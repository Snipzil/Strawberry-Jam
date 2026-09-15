const { app, BrowserWindow, shell, ipcMain, protocol, net, dialog, session, screen } = require('electron')
const path = require('path')
const fs = require('fs')
const fsPromises = fs.promises
const crypto = require('crypto')
const { fork } = require('child_process')
const Store = require('electron-store')
const os = require('os')
const chokidar = require('chokidar')
const processManager = require('../utils/ProcessManager')
const setupIpcHandlers = require('./ipcHandlers')
const Patcher = require('./renderer/application/patcher')
const { getDataPath, getAssetsPath } = require('../Constants')
const logManager = require('../utils/LogManager')
const AutoUpdateService = require('../services/update/AutoUpdateService')
const AppStateService = require('../services/state/AppStateService')
const WindowCreationService = require('../services/window/WindowCreationService')
const AppNotificationService = require('../services/notification/AppNotificationService')
const GlobalShortcutManager = require('../managers/shortcut/GlobalShortcutManager')
const CacheService = require('../services/cache/CacheService')

// Suppress Electron security warnings (nodeIntegration is required by the plugin system)
process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = 'true'

const KEYTAR_ACCOUNT_LEAK_CHECK_API_KEY = 'leak_checker_api_key'
const MIGRATION_FLAG_LEAK_CHECK_API_KEY_V1 = 'leakCheckApiKeyMigratedToKeytar_v1'

const isDevelopment = process.env.NODE_ENV === 'development'
const USER_DATA_PATH = app.getPath('userData')

const schema = {
  network: {
    type: 'object',
    properties: {
      smartfoxServer: {
        type: 'string',
        default: 'lb-iss02-classic-prod.animaljam.com'
      },
      secureConnection: {
        type: 'boolean',
        default: true
      }
    },
    default: {}
  },
  ui: {
    type: 'object',
    properties: {
      promptOnExit: {
        type: 'boolean',
        default: true
      },
      hideGamePlugins: {
        type: 'boolean',
        default: false
      },
      performServerCheckOnLaunch: {
        type: 'boolean',
        default: true
      },
      consoleDrawerHeight: {
        type: 'number',
        default: 200
      }
    },
    default: {}
  },
  logs: {
    type: 'object',
    properties: {
      consoleLimit: {
        type: 'number',
        default: 1000
      },
      networkLimit: {
        type: 'number',
        default: 1000
      }
    },
    default: {}
  },
  plugins: {
    type: 'object',
    properties: {
      usernameLogger: {
        type: 'object',
        properties: {
          apiKey: { type: 'string', default: '' },
          outputDir: { type: 'string', default: '' },
          autoCheck: {
            type: 'object',
            properties: {
              enabled: { type: 'boolean', default: false },
              threshold: { type: 'number', default: 100 }
            },
            default: {}
          },
          collection: {
            type: 'object',
            properties: {
              enabled: { type: 'boolean', default: true },
              collectNearby: { type: 'boolean', default: true },
              collectBuddies: { type: 'boolean', default: true }
            },
            default: {}
          }
        },
        default: {}
      },
      sidebar: {
        type: 'object',
        properties: {
          customIcons: { type: 'object', default: {} },
          hiddenPlugins: {
            type: 'array',
            items: { type: 'string' },
            default: []
          },
          sortMode: {
            type: 'string',
            enum: ['type', 'alphabetical', 'custom'],
            default: 'type'
          },
          customOrder: {
            type: 'array',
            items: { type: 'string' },
            default: []
          }
        },
        default: {}
      }
    },
    default: {}
  },
  updates: {
    type: 'object',
    properties: {
      enableAutoUpdates: {
        type: 'boolean',
        default: true
      }
    },
    default: {}
  },
  game: {
    type: 'object',
    properties: {},
    additionalProperties: true
  }
}

const DEFAULT_APP_STATE = {
  leakCheck: {
    inputFilePath: null,
    lastProcessedIndex: -1,
    status: 'idle'
  }
}

/**
 * Default window options.
 * @type {Object}
 * @constant
 */
const defaultWindowOptions = {
  title: 'Jam',
  backgroundColor: '#16171f',
  resizable: true,
  useContentSize: true,
  width: 840,
  height: 645,
  frame: false,
  webPreferences: {
    webSecurity: false,
    contextIsolation: false,
    nodeIntegration: true,
    nodeIntegrationInSubFrames: true,
    webviewTag: true,
    plugins: true,
    preload: path.resolve(__dirname, 'preload.js'),
    additionalArguments: ['--disable-electron-security-warnings']
  }
}

/**
 * Console messages that should never be echoed to the process stdout.
 * @param {string} message
 * @returns {boolean}
 */
const isNoisyConsoleMessage = (message) => {
  if (typeof message !== 'string') return false
  return message.includes('Electron Security Warning') ||
    message.includes('InvisibleToggle:') ||
    message.includes('InvisibleToggle loaded.')
}

/**
 * Attaches a console-message filter to a webContents instance.
 * @param {Electron.WebContents} webContents
 */
const attachConsoleFilter = (webContents) => {
  webContents.on('console-message', (details) => {
    if (isNoisyConsoleMessage(details.message)) details.preventDefault()
  })
}

const KEEPALIVE_CLEAR_SCRIPT = `
  if (window._backgroundKeepAliveInterval) {
    clearInterval(window._backgroundKeepAliveInterval);
    window._backgroundKeepAliveInterval = null;
  }
`

protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { standard: true, secure: true, supportFetchAPI: true } }
])

class Electron {
  constructor () {
    this._window = null
    this._gameWindow = null
    this._apiProcess = null
    this._apiPort = null
    this._store = new Store({ schema })
    this._swfFileWatcher = null
    this._patcher = null
    this._isQuitting = false
    this._isClearingCacheAndQuitting = false
    this._savedWindowState = null
    this._cachedJQuery = null
    this._cachedJQueryUI = null
    this.pluginWindows = new Map()
    this._backgroundPlugins = new Set()
    this._backgroundIntervals = new Map()
    this.manualCheckInProgressRef = { value: false }

    try {
      this.keytar = require('keytar')
    } catch (e) {
      logManager.warn('[Electron] keytar not available, credential storage will use fallback')
      this.keytar = {
        getPassword: async () => null,
        setPassword: async () => {},
        deletePassword: async () => {}
      }
    }

    this.keytarServiceLeakCheckApiKey = `${app.getName()}-leak-check-api-key`

    this._migrateLeakCheckApiKeyToKeytar().catch(err => {
      console.error(`[Migration] Error during leak check API key migration: ${err.message}`)
    })

    setupIpcHandlers(this)
    this._setupFileOpeningIPC()
    this._setupCleanupHandlers()

    this.autoUpdateService = new AutoUpdateService(app, this._store, this._window, this.manualCheckInProgressRef)
    this.appStateService = new AppStateService(app, DEFAULT_APP_STATE)
    this.windowCreationService = new WindowCreationService(defaultWindowOptions)
    this.appNotificationService = new AppNotificationService(this._window, this.pluginWindows, this._backgroundPlugins)
    this.globalShortcutManager = new GlobalShortcutManager()
    this.cacheService = new CacheService()

    ipcMain.on('broadcast-to-plugins', (event, channel, ...args) => {
      this.pluginWindows.forEach((window) => {
        if (window && !window.isDestroyed()) {
          window.webContents.send(channel, ...args)
        }
      })
    })
  }

  _loadJQueryCache () {
    if (this._cachedJQuery) return
    try {
      this._cachedJQuery = fs.readFileSync(require.resolve('jquery/dist/jquery.min.js'), 'utf8')
    } catch (e) {
      this._cachedJQuery = null
    }
    try {
      this._cachedJQueryUI = fs.readFileSync(path.join(__dirname, '..', '..', 'assets', 'scripts', 'jquery-ui.js'), 'utf8')
    } catch (e) {
      this._cachedJQueryUI = null
    }
  }

  async _migrateLeakCheckApiKeyToKeytar () {
    if (this._store.get(MIGRATION_FLAG_LEAK_CHECK_API_KEY_V1)) return

    const oldApiKey = this._store.get('leakCheck.apiKey')

    if (typeof oldApiKey === 'string' && oldApiKey.trim() !== '') {
      try {
        await this.keytar.setPassword(this.keytarServiceLeakCheckApiKey, KEYTAR_ACCOUNT_LEAK_CHECK_API_KEY, oldApiKey)
        this._store.set('leakCheck.apiKey', '')
        this._store.set(MIGRATION_FLAG_LEAK_CHECK_API_KEY_V1, true)
      } catch (err) {
        if (isDevelopment) console.error(`[Migration LeakCheck][Keytar] Stack: ${err.stack}`)
      }
    } else {
      this._store.set(MIGRATION_FLAG_LEAK_CHECK_API_KEY_V1, true)
    }
  }

  _handleOpenPluginWindow (event, { url, name, pluginPath }) {
    const existingWindow = this.pluginWindows.get(name)
    if (existingWindow && !existingWindow.isDestroyed()) {
      if (existingWindow.isMinimized()) existingWindow.restore()
      existingWindow.focus()
      this.messageWindow('plugin-window-focused', name)
      return
    }

    let runInBackground = false
    try {
      const configPath = path.join(pluginPath, 'plugin.json')
      if (fs.existsSync(configPath)) {
        const pluginConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'))
        runInBackground = pluginConfig.runInBackground === true
        if (runInBackground) this._backgroundPlugins.add(name)
      }
    } catch (err) {
      console.warn(`[Plugin Window] Could not read plugin.json for ${name}: ${err.message}`)
    }

    const pluginWindow = new BrowserWindow({
      ...defaultWindowOptions,
      title: name,
      width: 800,
      height: 600,
      icon: path.join(getAssetsPath(app), 'images', 'icon.png'),
      webPreferences: {
        ...defaultWindowOptions.webPreferences,
        devTools: true,
        backgroundThrottling: !runInBackground
      }
    })

    attachConsoleFilter(pluginWindow.webContents)
    pluginWindow.loadURL(url)

    pluginWindow.webContents.on('did-finish-load', () => {
      pluginWindow.focus()

      this._loadJQueryCache()
      const jqInjection = this._cachedJQuery
        ? `if (!window.jQuery) { ${this._cachedJQuery}\n }`
        : ''
      const jqUIInjection = this._cachedJQueryUI
        ? `if (window.jQuery && !window.jQuery.ui) { ${this._cachedJQueryUI}\n }`
        : ''

      pluginWindow.webContents.executeJavaScript(jqInjection)
        .then(() => pluginWindow.webContents.executeJavaScript(jqUIInjection))
        .then(() => pluginWindow.webContents.executeJavaScript(`
          try {
            const { ipcRenderer } = require('electron');

            window.jam = window.jam || {};

            window.jam.dispatch = {
              sendRemoteMessage: function (msg, options) {
                ipcRenderer.send('send-remote-message', { message: msg, options: options || {} });
              },
              sendConnectionMessage: function (msg) {
                ipcRenderer.send('send-connection-message', msg);
              },
              getState: function (key) {
                return ipcRenderer.invoke('dispatch-get-state', key);
              },
              getStateSync: function (key) {
                return ipcRenderer.sendSync('dispatch-get-state-sync', key);
              },
              getConnectedClients: function () {
                return ipcRenderer.invoke('dispatch-get-connected-clients');
              },
              runInBackground: ${runInBackground}
            };

            window.jam.application = {
              consoleMessage: function (type, msg) {
                ipcRenderer.send('console-message', { type, msg });
              }
            };

            window.jam.isAppMinimized = false;

            window.dispatchEvent(new CustomEvent('jam-ready'));
          } catch (err) {
            console.error('[Plugin Window] Error setting up window.jam:', err);
          }
        `))
        .catch(err => console.error(`[Plugin Window] Failed to bootstrap ${name}: ${err.message}`))
    })

    this.pluginWindows.set(name, pluginWindow)
    this.messageWindow('plugin-window-opened', name)

    pluginWindow.on('closed', () => {
      if (!this._isQuitting) this.messageWindow('plugin-window-closed', name)

      this._backgroundIntervals.delete(name)
      this.pluginWindows.delete(name)
      this._backgroundPlugins.delete(name)
    })

    pluginWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
      console.error(`[Plugin Window] ${name} failed to load (${errorCode}): ${errorDescription}`)
    })
  }

  _handleOpenGameWindow () {
    if (this._gameWindow && !this._gameWindow.isDestroyed()) {
      if (this._gameWindow.isMinimized()) this._gameWindow.restore()
      this._gameWindow.focus()
      return
    }

    const gameWindow = new BrowserWindow({
      ...defaultWindowOptions,
      title: 'Game Client',
      width: 1024,
      height: 768,
      icon: path.join(getAssetsPath(app), 'images', 'icon.png')
    })

    gameWindow.loadFile(path.join(app.getAppPath(), 'assets', 'client', 'gui', 'index.html'))
    this._gameWindow = gameWindow

    gameWindow.webContents.on('dom-ready', () => {
      const config = require(path.join(app.getAppPath(), 'assets', 'client', 'config.js'))

      gameWindow.webContents.send('postSystemData', {
        version: app.getVersion(),
        platform: os.platform(),
        platformRelease: os.release(),
        language: this._store.get('login.language') || 'en',
        affiliateCode: this._store.get('login.affiliateCode') || ''
      })

      gameWindow.webContents.send('loginInfoLoaded', {
        username: this._store.get('login.username', ''),
        rememberMe: this._store.get('login.rememberMe', false),
        authToken: null,
        refreshToken: null,
        config,
        df: crypto.randomUUID(),
        rcToken: ''
      })
    })

    gameWindow.on('closed', () => {
      this._gameWindow = null
      this._clearAllTokens()
    })
  }

  _clearAllTokens () {
    try {
      this._store.delete('login.authToken')
      this._store.delete('login.refreshToken')

      const accounts = (this._store.store || {}).accounts || {}
      for (const username of Object.keys(accounts)) {
        this._store.delete(`accounts.${username}.authToken`)
        this._store.delete(`accounts.${username}.refreshToken`)
      }
      console.log('[Token Cleanup] Cleared all stored auth/refresh tokens')
    } catch (err) {
      console.error(`[Token Cleanup] Failed to clear tokens: ${err.message}`)
    }
  }

  getAppState () {
    return this.appStateService.getAppState()
  }

  setAppState (newState) {
    return this.appStateService.setAppState(newState)
  }

  async _confirmNoOtherInstances (actionDescription) {
    if (app.requestSingleInstanceLock()) {
      app.releaseSingleInstanceLock()
      return true
    }

    const choice = await dialog.showMessageBox(this._window, {
      type: 'warning',
      title: 'Multiple Instances Detected',
      message: `It looks like another Strawberry Jam window is open.\n\nPlease close all other Strawberry Jam windows before attempting to ${actionDescription}.`,
      buttons: ['Cancel', 'I have closed other windows'],
      defaultId: 0,
      cancelId: 0
    })
    return choice.response === 1
  }

  _getCachePaths () {
    return this.cacheService.getCachePaths()
  }

  _clearAppCache () {
    return this.cacheService.clearAppCache()
  }

  _getUninstallerPath () {
    return this.cacheService.getUninstallerPath()
  }

  create () {
    logManager.initialize({
      appDataPath: USER_DATA_PATH,
      maxMemoryLogs: this._store.get('logs.networkLimit', 1000)
    })

    console.log = (message) => logManager.log(message, 'main', logManager.logLevels.INFO)
    console.error = (message) => logManager.log(message, 'main', logManager.logLevels.ERROR)
    console.warn = (message) => logManager.log(message, 'main', logManager.logLevels.WARN)

    app.whenReady().then(async () => {
      // Clear any problematic cache state early to prevent hangs
      await session.defaultSession.clearCache().catch(() => {})

      protocol.handle('app', (request) => {
        const url = request.url.slice('app://'.length)
        const filePath = url.startsWith('assets/')
          ? path.join(getAssetsPath(app), url.substring('assets/'.length))
          : path.normalize(`${__dirname}/../../${url}`)

        return net.fetch(`file://${filePath}`)
      })

      await this._onReady()

      if (!this._window) return

      this._window.on('enter-full-screen', () => this.messageWindow('fullscreen-changed', true))
      this._window.on('leave-full-screen', () => {
        this.messageWindow('fullscreen-changed', false)
        if (this._savedWindowState) {
          this._window.setBounds(this._savedWindowState.bounds)
          if (this._savedWindowState.isMaximized) this._window.maximize()
        }
      })
      this._window.on('maximize', () => this.messageWindow('maximize-changed', true))
      this._window.on('unmaximize', () => this.messageWindow('maximize-changed', false))
      this._window.on('minimize', () => this._handleAppMinimized())
      this._window.on('restore', () => this._handleAppRestored())
      this._window.on('focus', () => this._handleAppRestored())
    })

    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') app.quit()
    })

    return this
  }

  _registerShortcut (key, callback) {
    this.globalShortcutManager.register(key, callback)
  }

  _createWindow ({ url, frameName }) {
    return this.windowCreationService.createWindow({ url, frameName })
  }

  /**
   * Sends a message to the main window if it is still alive.
   * @param {string} type
   * @param {*} [message]
   */
  messageWindow (type, message = {}) {
    if (this._window && !this._window.isDestroyed() && this._window.webContents && !this._window.webContents.isDestroyed()) {
      this._window.webContents.send(type, message)
    }
  }

  _setupZoomHandling (win) {
    const MIN_ZOOM = -3
    const MAX_ZOOM = 3

    win.webContents.on('before-input-event', (event, input) => {
      if (!input.control || input.type !== 'keyDown') return

      const current = win.webContents.getZoomLevel()
      if (input.key === '0') {
        win.webContents.setZoomLevel(0)
      } else if (input.key === '=' || input.key === '+') {
        win.webContents.setZoomLevel(Math.min(current + 0.5, MAX_ZOOM))
      } else if (input.key === '-') {
        win.webContents.setZoomLevel(Math.max(current - 0.5, MIN_ZOOM))
      } else {
        return
      }
      event.preventDefault()
    })
  }

  _resolveInitialBounds () {
    const savedBounds = this._store.get('windowBounds')

    if (savedBounds && savedBounds.width > 200 && savedBounds.height > 200) {
      const visible = screen.getAllDisplays().some(({ bounds: b }) =>
        savedBounds.x >= b.x - 50 && savedBounds.y >= b.y - 50 &&
        savedBounds.x < b.x + b.width && savedBounds.y < b.y + b.height
      )
      if (visible) return savedBounds
    }

    const { width, height } = screen.getPrimaryDisplay().workAreaSize
    const w = Math.floor(width * 0.57)
    const h = Math.floor(height * 0.8)
    return { x: Math.floor((width - w) / 2), y: Math.floor((height - h) / 2), width: w, height: h }
  }

  async _onReady () {
    ipcMain.on('request-main-log-path', (event) => {
      if (event.sender && !event.sender.isDestroyed()) {
        event.sender.send('response-main-log-path', logManager.logPath || '')
      }
    })

    const assetsPath = getAssetsPath(app)
    const dataPath = getDataPath(app)

    this._patcher = new Patcher(null, assetsPath)
    this._window = new BrowserWindow({
      ...defaultWindowOptions,
      icon: path.join(assetsPath, 'images', 'icon.png')
    })
    this.autoUpdateService.window = this._window
    this.appNotificationService.window = this._window

    this._window.setBounds(this._resolveInitialBounds())
    attachConsoleFilter(this._window.webContents)
    this._setupZoomHandling(this._window)

    await this._window.loadFile(path.join(__dirname, 'renderer', 'index.html'))

    const FilesController = require('../api/controllers/FilesController')
    FilesController.initialize(app)

    this.messageWindow('set-data-path', dataPath)
    this.messageWindow('set-assets-path', assetsPath)
    this.messageWindow('set-user-data-path', USER_DATA_PATH)

    this._window.webContents.setWindowOpenHandler((details) => this._createWindow(details))

    this._window.on('close', () => {
      try {
        if (this._window && !this._window.isDestroyed()) {
          this._store.set('windowBounds', this._window.getBounds())
        }
      } catch (_) {}
    })

    this._window.on('closed', () => {
      this._clearAllTokens()
      const mainWindowId = this._window ? this._window.id : -1

      BrowserWindow.getAllWindows().forEach(win => {
        if (win && win.id !== mainWindowId && !win.isDestroyed()) {
          try {
            win.destroy()
          } catch (e) {
            console.error(`[Main Window Closed] Error destroying window: ${e.message}`)
          }
        }
      })

      this.pluginWindows.clear()
      this._backgroundPlugins.clear()
      this._closeSwfFileWatcher()
      this._window = null
    })

    try {
      await fsPromises.mkdir(dataPath, { recursive: true })
    } catch (error) {
      console.error(`[Electron] Error creating data directory: ${error.message}`)
    }

    this._startApiProcess(assetsPath)

    if (isDevelopment) {
      this.globalShortcutManager.registerDevToolsShortcut()
    }

    await Promise.all([
      Promise.resolve(this.autoUpdateService.initialize()).catch(() => {}),
      this._autoReapplySwfIfNeeded().catch(e => console.error(`Error applying SWF on launch: ${e.message}`)),
      this._setupSwfFileWatcher()
    ])
  }

  _startApiProcess (assetsPath) {
    try {
      this._apiProcess = fork(path.join(__dirname, '..', 'api', 'index.js'), [], {
        silent: false,
        env: {
          ...process.env,
          STRAWBERRY_JAM_ASSETS_PATH: assetsPath
        }
      })
      processManager.add(this._apiProcess)

      this._apiProcess.on('error', (error) => {
        console.error(`[API Process] Error: ${error.message}`)
      })

      this._apiProcess.on('message', (message) => {
        if (message && message.type === 'api-port' && message.port) {
          this._apiPort = message.port
        }
      })

      this._apiProcess.on('exit', (code) => {
        if (code !== 0) {
          this.messageWindow('port-error', {
            server: 'api',
            message: 'The API server failed to start because port 7681 is busy. Close other applications using this port or use the /terminate command, then restart.'
          })
        }
      })

      this.appNotificationService.notifyStrawberryJamClose(this._apiProcess)
    } catch (error) {
      // Continue startup even if the API process fails; most functionality doesn't depend on it.
      console.error(`[API Process] Failed to start: ${error.message}`)
    }
  }

  async _reapplySwfIfModified (filename, { logPrefix }) {
    const FilesController = require('../api/controllers/FilesController')
    const sourceFilePath = path.join(FilesController.optionsDir, filename)

    let stats
    try {
      stats = await fsPromises.stat(sourceFilePath)
    } catch (_) {
      return
    }

    const currentModifiedTime = stats.mtime.getTime()
    const lastModifiedKey = `game.swfLastModified.${filename}`
    const lastModifiedTime = this._store.get(lastModifiedKey)

    if (lastModifiedTime && currentModifiedTime <= lastModifiedTime) return

    logManager.log(`${logPrefix} Detected modification to ${filename}, reapplying...`, 'main', logManager.logLevels.INFO)
    const result = await FilesController.replaceSwfFile(filename)
    if (result.success) {
      this._store.set(lastModifiedKey, currentModifiedTime)
      this.messageWindow('swf-auto-reapplied')
    } else {
      console.error(`${logPrefix} Failed to reapply ${filename}: ${result.error}`)
    }
  }

  async _autoReapplySwfIfNeeded () {
    const selectedFile = this._store.get('game.selectedSwfFile')
    if (!selectedFile) return
    await this._reapplySwfIfModified(selectedFile, { logPrefix: '[Auto Reapply]' })
  }

  _closeSwfFileWatcher () {
    if (!this._swfFileWatcher) return
    try {
      this._swfFileWatcher.close()
    } catch (error) {
      console.error(`[SWF Watcher] Error closing file watcher: ${error.message}`)
    }
    this._swfFileWatcher = null
  }

  async _setupSwfFileWatcher () {
    try {
      const FilesController = require('../api/controllers/FilesController')
      const optionsDir = FilesController.optionsDir
      if (!optionsDir) return

      const dirExists = await fsPromises.access(optionsDir).then(() => true).catch(() => false)
      if (!dirExists) return

      this._closeSwfFileWatcher()

      this._swfFileWatcher = chokidar.watch(optionsDir, {
        ignored: (filePath, stats) => Boolean(stats && stats.isFile() && !filePath.toLowerCase().endsWith('.swf')),
        depth: 0,
        persistent: true,
        ignoreInitial: true,
        usePolling: true,
        interval: 1000,
        awaitWriteFinish: {
          stabilityThreshold: 2000,
          pollInterval: 500
        }
      })

      this._swfFileWatcher.on('change', async (filePath) => {
        const filename = path.basename(filePath)
        if (this._store.get('game.selectedSwfFile') !== filename) return
        try {
          await this._reapplySwfIfModified(filename, { logPrefix: '[SWF Watcher]' })
        } catch (error) {
          console.error(`[SWF Watcher] Error handling file change: ${error.message}`)
        }
      })

      this._swfFileWatcher.on('error', (error) => {
        console.error(`[SWF Watcher] Watcher error: ${error.message}`)
      })

      logManager.log('[SWF Watcher] File watcher initialized', 'main', logManager.logLevels.INFO)
    } catch (error) {
      console.error(`[SWF Watcher] Failed to setup file watcher: ${error.message}`)
    }
  }

  _forEachLivePluginWindow (callback) {
    this.pluginWindows.forEach((window, name) => {
      if (window.isDestroyed() || !window.webContents || window.webContents.isDestroyed()) return
      try {
        callback(window, name)
      } catch (err) {
        console.warn(`[Plugin Window] ${name}: ${err.message}`)
      }
    })
  }

  _handleAppMinimized () {
    this._forEachLivePluginWindow((window, name) => {
      window.webContents.send('app-minimized')
      window.webContents.executeJavaScript('window.jam.isAppMinimized = true;').catch(() => {})

      if (this._backgroundPlugins.has(name)) {
        this._enableBackgroundProcessing(window, name)
      }
    })

    this.messageWindow('app-minimized')
  }

  _enableBackgroundProcessing (window, name) {
    if (this._backgroundIntervals.has(name)) return

    window.webContents.backgroundThrottling = false
    window.webContents.executeJavaScript(`
      (function() {
        if (!window._backgroundKeepAliveInterval) {
          window._backgroundKeepAliveInterval = setInterval(() => {
            if (typeof window.jam !== 'undefined' && window.jam.dispatch && window.jam.dispatch.runInBackground) {
              window.dispatchEvent(new CustomEvent('jam-background-tick', {
                detail: { timestamp: Date.now() }
              }));
            }
          }, 5000);
        }
        return window._backgroundKeepAliveInterval;
      })();
    `).then((intervalId) => {
      if (intervalId) this._backgroundIntervals.set(name, intervalId)
    }).catch(() => {})
  }

  _handleAppRestored () {
    this._forEachLivePluginWindow((window, name) => {
      window.webContents.send('app-restored')
      window.webContents.executeJavaScript('window.jam.isAppMinimized = false;').catch(() => {})

      if (this._backgroundIntervals.has(name)) {
        window.webContents.executeJavaScript(KEEPALIVE_CLEAR_SCRIPT).catch(() => {})
        this._backgroundIntervals.delete(name)
      }

      window.webContents.executeJavaScript(`
        window.dispatchEvent(new CustomEvent('jam-foreground', {
          detail: { timestamp: Date.now() }
        }));
      `).catch(() => {})
    })

    this.messageWindow('app-restored')
  }

  _setupFileOpeningIPC () {
    ipcMain.on('open-file-in-editor', (event, relativePath) => {
      const pluginWindow = BrowserWindow.fromWebContents(event.sender)
      if (!pluginWindow) return

      let pluginName = null
      for (const [name, window] of this.pluginWindows.entries()) {
        if (window === pluginWindow) {
          pluginName = name
          break
        }
      }
      if (!pluginName || !this._window || this._window.isDestroyed()) return

      ipcMain.once('plugin-path-response', (e, pluginPath) => {
        if (!pluginPath) return
        const fullPath = path.join(pluginPath, relativePath)
        shell.openPath(fullPath).catch(err => {
          console.error(`[Electron] Failed to open file: ${fullPath} (${err.message})`)
        })
      })
      this._window.webContents.send('get-plugin-path', pluginName)
    })
  }

  _setupCleanupHandlers () {
    const performCleanup = async (signal) => {
      if (this._isQuitting) return
      this._isQuitting = true

      logManager.log(
        signal ? `[Electron] ${signal} received, starting cleanup` : '[Electron] will-quit event triggered, starting cleanup',
        'main'
      )

      const cleanupPromises = []

      if (this._window && !this._window.isDestroyed() && this._window.webContents) {
        cleanupPromises.push(new Promise((resolve) => {
          this._window.webContents.send('app-cleanup-request')
          setTimeout(resolve, 500)
        }))
      }

      this._forEachLivePluginWindow((window) => {
        window.webContents.executeJavaScript(KEEPALIVE_CLEAR_SCRIPT).catch(() => {})
      })
      this._backgroundIntervals.clear()
      this._closeSwfFileWatcher()

      await Promise.all(cleanupPromises)
      await processManager.killAll(null)

      if (signal) process.exit(0)
    }

    app.on('will-quit', () => performCleanup(null))

    const handleSignal = (signal) => {
      if (this._isQuitting) return
      logManager.log(`[Electron] Received ${signal}, initiating cleanup...`, 'main')
      performCleanup(signal).catch((err) => {
        logManager.error(`[Electron] Error during ${signal} cleanup: ${err.message}`)
        process.exit(1)
      })
    }

    process.on('SIGINT', () => handleSignal('SIGINT'))
    process.on('SIGTERM', () => handleSignal('SIGTERM'))

    process.on('exit', (code) => {
      if (!this._isQuitting) {
        logManager.log(`[Electron] Process exiting with code ${code}, performing emergency cleanup`, 'main')
        processManager._emergencyCleanup()
      }
    })

    ipcMain.on('application-cleanup-complete', () => {
      logManager.log('[Electron] Application cleanup completed', 'main')
    })
  }
}

module.exports = Electron
