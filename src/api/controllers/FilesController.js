const axios = require('axios')
const path = require('path')
const fs = require('fs')
const fsPromises = fs.promises

// The client shipped with this release. Bump it (and add the file to
// assets/flash/options) whenever a new ajclient.swf is released.
const LATEST_SWF_FILE = 'v6.2.2.swf'
// Earlier "latest" clients. Anyone still on one of these is moved to
// LATEST_SWF_FILE on startup, since it was the default rather than a choice.
// anim-pool-fix-test.swf was the pre-release test build of v6.2.1, and
// masterpieces-test.swf a pre-release test build of v6.2.2.
const PREVIOUS_LATEST_SWF_FILES = ['v6.0.0.swf', 'v6.0.1.swf', 'v6.0.3.swf', 'v6.0.4.swf', 'v6.0.5.swf', 'v6.1.0.swf', 'v6.2.0.swf', 'v6.2.1.swf', 'anim-pool-fix-test.swf', 'masterpieces-test.swf']

class FilesController {
  constructor(app = null) {
    this._app = app;
    this._assetsPath = null;
    this._flashDir = null;
    this._optionsDir = null;
    this._initialized = false;
    
    if (app) {
      this._initializePaths(app);
    }
  }
  
  _initializePaths(app) {
    const { getAssetsPath } = require('../../Constants');
    this._assetsPath = getAssetsPath(app);
    this._flashDir = path.join(this._assetsPath, 'flash');
    this._optionsDir = path.join(this._flashDir, 'options');
    this._initialized = true;
  }
  
  initialize(app) {
    if (!app) {
      throw new Error('FilesController.initialize requires the Electron app object');
    }
    this._app = app;
    this._initializePaths(app);
  }
  
  _ensureInitialized() {
    if (this._initialized) {
      return;
    }
    
    if (this._app) {
      this._initializePaths(this._app);
    } else {
      let assetsPath;
      if (process.env.STRAWBERRY_JAM_ASSETS_PATH) {
        assetsPath = process.env.STRAWBERRY_JAM_ASSETS_PATH;
      } else if (process.resourcesPath) {
        assetsPath = path.join(process.resourcesPath, 'assets');
      } else {
        assetsPath = path.join(__dirname, '../../assets');
      }
      this._assetsPath = assetsPath;
      this._flashDir = path.join(assetsPath, 'flash');
      this._optionsDir = path.join(this._flashDir, 'options');
      this._initialized = true;
    }
  }
  
  get flashDir() {
    this._ensureInitialized();
    return this._flashDir;
  }
  
  get optionsDir() {
    this._ensureInitialized();
    return this._optionsDir;
  }

  /**
   * Host endpoint.
   */
  get baseUrl () {
    return 'https://ajcontent.akamaized.net'
  }

  /**
   * Request headers.
   */
  get baseHeaders () {
    return {
      Host: 'ajcontent.akamaized.net',
      Referer: 'https://desktop.animaljam.com/gameClient/game/index.html'
    }
  }

  /**
   * Initializes the SWF system.
   * This should be called on application startup.
   * @returns {Promise<void>}
   */
  async initializeSwf() {
    try {
      await fsPromises.mkdir(this.optionsDir, { recursive: true })

      const activeSwfPath = path.join(this.flashDir, 'ajclient.swf')
      const prodSwfPath = path.join(this.optionsDir, LATEST_SWF_FILE)

      const [activeExists, prodExists] = await Promise.all([
        fsPromises.access(activeSwfPath).then(() => true).catch(() => false),
        fsPromises.access(prodSwfPath).then(() => true).catch(() => false)
      ])

      if (!activeExists && prodExists) {
        await fsPromises.copyFile(prodSwfPath, activeSwfPath)
      }
    } catch (error) {
      console.error('Failed to initialize SWF system:', error)
    }
  }

  /**
   * Gets the selected SWF file from settings.
   * This always returns 'ajclient.swf' because the active file is always a copy.
   */
  getSelectedSwfFile () {
    return 'ajclient.swf'
  }

  /**
   * Replaces the active ajclient.swf with the selected file from the options.
   * @param {string} selectedFile - The filename to make active
   * @returns {Promise<{success: boolean, message?: string, error?: string}>}
   */
  async replaceSwfFile(selectedFile) {
    const targetFile = path.join(this.flashDir, 'ajclient.swf')
    const sourceFromOptions = path.join(this.optionsDir, selectedFile)

    try {
      const sourceExists = await fsPromises.access(sourceFromOptions).then(() => true).catch(() => false)
      if (!sourceExists) {
        return { success: false, error: `Option for ${selectedFile} not found.` }
      }

      await fsPromises.copyFile(sourceFromOptions, targetFile)

      return {
        success: true,
        message: `Successfully switched to ${selectedFile}`
      }
    } catch (error) {
      console.error('Error replacing SWF file:', error)
      return {
        success: false,
        error: `Failed to replace SWF file: ${error.message}`
      }
    }
  }

  /**
   * Gets the currently active SWF file info by comparing it against options.
   * @returns {Object} Info about the currently active file
   */
  async getActiveSwfInfo() {
    const targetFile = path.join(this.flashDir, 'ajclient.swf')

    try {
      let stats
      try {
        stats = await fsPromises.stat(targetFile)
      } catch (e) {
        return { active: null, error: 'Active SWF or options directory not found.' }
      }

      let detectedSource = 'ajclient.swf'

      let optionEntries
      try {
        optionEntries = await fsPromises.readdir(this.optionsDir)
      } catch (e) {
        return { active: detectedSource, size: stats.size, modified: stats.mtime }
      }

      const optionFiles = optionEntries.filter(f => f.endsWith('.swf'))
      for (const filename of optionFiles) {
        const optionPath = path.join(this.optionsDir, filename)
        try {
          const optionStats = await fsPromises.stat(optionPath)
          if (optionStats.size === stats.size) {
            detectedSource = filename
            break
          }
        } catch (e) {
          continue
        }
      }

      return {
        active: detectedSource,
        size: stats.size,
        modified: stats.mtime
      }
    } catch (error) {
      console.error('Error getting active SWF info:', error.message)
      return { active: null, error: error.message }
    }
  }

  /**
   * Gets all available SWF files that can be selected.
   * @returns {Array<string>} Array of available SWF filenames
   */
  async getAvailableSwfFiles () {
    try {
      let entries
      try {
        entries = await fsPromises.readdir(this.optionsDir, { withFileTypes: true })
      } catch (e) {
        return [LATEST_SWF_FILE]
      }
      const files = entries
        .filter(entry => !entry.isDirectory() && entry.name.endsWith('.swf'))
        .map(entry => entry.name)
      const order = [LATEST_SWF_FILE, 'v6.2.1.swf', 'v6.2.0.swf', 'v6.1.0.swf', 'v6.0.5.swf', 'v6.0.4.swf', 'v6.0.3.swf', 'v6.0.1.swf', 'v6.0.0.swf', 'v5.2.0.swf', 'v4.2.3.swf', 'non-purple-private-chat.swf', 'unmodded-ajclient.swf']
      return [...new Set(files)].sort((a, b) => {
        const ai = order.indexOf(a)
        const bi = order.indexOf(b)
        if (ai === -1 && bi === -1) return a.localeCompare(b)
        if (ai === -1) return 1
        if (bi === -1) return -1
        return ai - bi
      })
    } catch (error) {
      console.error('Error scanning for SWF files:', error)
      return [LATEST_SWF_FILE]
    }
  }

  async getSwfFileInfo () {
    const files = await this.getAvailableSwfFiles()
    const displayNames = {
      'v6.2.2.swf': 'v6.2.2 (latest)',
      'v6.2.1.swf': 'v6.2.1 (previous)',
      'v6.2.0.swf': 'v6.2.0 (older)',
      'v6.1.0.swf': 'v6.1.0 (older)',
      'v6.0.5.swf': 'v6.0.5 (older)',
      'v6.0.4.swf': 'v6.0.4 (older)',
      'v6.0.3.swf': 'v6.0.3 (older)',
      'v6.0.1.swf': 'v6.0.1 (older)',
      'v6.0.0.swf': 'v6.0.0 (older)',
      'v5.2.0.swf': 'v5.2.0 (older)',
      'v4.2.3.swf': 'v4.2.3 (older)',
      'non-purple-private-chat.swf': 'Non-Colored Private Chat (outdated)',
      'unmodded-ajclient.swf': 'Unmodded (latest)'
    }

    return Promise.all(files.map(async (filename) => {
      const optionPath = path.join(this.optionsDir, filename)
      let stats = null

      try {
        stats = await fsPromises.stat(optionPath)
      } catch (e) {}

      return {
        filename,
        displayName: displayNames[filename] || filename.replace('.swf', ''),
        size: stats ? stats.size : 0,
        modified: stats ? stats.mtime : null,
        exists: stats !== null
      }
    }))
  }

  /**
   * Serves the active ajclient.swf file.
   */
  async game (request, response) {
    const activeSwfPath = path.join(this.flashDir, 'ajclient.swf')

    try {
      await fsPromises.access(activeSwfPath)
    } catch (e) {
      console.error(`Active SWF file not found: ${activeSwfPath}`)
      return response.status(404).send('SWF file not found')
    }

    response.set({
      'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      'Pragma': 'no-cache',
      'Expires': '0'
    })
    return response.sendFile(activeSwfPath)
  }


  async index (request, response) {
    const requestPath = request.path.toLowerCase();
    
    if (requestPath.includes('ajclient.swf')) {
      const legitimatePattern = /^\/\d{4}\/ajclient\.swf$/;
      if (legitimatePattern.test(request.path)) {
        console.log(`[SWF Update Blocker] Legitimate SWF request reached index(), serving locally: ${request.path}`);
        return this.game(request, response);
      } else {
        console.log(`[SWF Update Blocker] Blocked SWF update request: ${request.path}`);
        console.log(`[SWF Update Blocker] Note: Legitimate SWF requests should match /{4-digit}/ajclient.swf pattern`);
        return response.status(404).send('SWF update blocked - using local modded SWF');
      }
    }
    
    // Handle wall requests - proxy to prod-wall.animaljam.com instead of ajcontent.akamaized.net
    if (requestPath.startsWith('/wall')) {
      return this._proxyRequest(request, response, {
        baseUrl: 'https://prod-wall.animaljam.com',
        host: 'prod-wall.animaljam.com'
      })
    }

    if (requestPath.startsWith('/game/mp')) {
      return this._proxyRequest(request, response, {
        baseUrl: 'https://jammercentral.animaljam.com',
        host: 'jammercentral.animaljam.com'
      })
    }

    try {
      const proxyResponse = await axios({
        method: 'GET',
        url: `${this.baseUrl}${request.path}`,
        headers: { ...this.baseHeaders, ...this._passthroughRequestHeaders(request) },
        responseType: 'stream',
        decompress: false,
        timeout: 30000,
        validateStatus: () => true
      })
      this._pipeProxyResponse(proxyResponse, response)
    } catch (error) {
      if (!response.headersSent) {
        response.status(502).send('Proxy error')
      }
    }
  }

  /**
   * Client headers that let the CDN answer with 304s and compressed bodies.
   */
  _passthroughRequestHeaders (request) {
    const headers = {}
    for (const name of ['if-none-match', 'if-modified-since', 'accept-encoding']) {
      if (request.headers[name]) headers[name] = request.headers[name]
    }
    return headers
  }

  /**
   * Relays status and caching headers so the game client can cache assets
   * instead of re-downloading every one on each load.
   */
  _pipeProxyResponse (proxyResponse, response) {
    response.status(proxyResponse.status)
    for (const name of ['content-type', 'content-length', 'content-encoding', 'cache-control', 'etag', 'last-modified', 'expires']) {
      const value = proxyResponse.headers[name]
      if (value !== undefined) response.set(name, value)
    }
    proxyResponse.data.pipe(response)
  }

  async _proxyRequest(request, response, { baseUrl, host }) {
    const headers = {
      Host: host,
      Referer: 'https://desktop.animaljam.com/gameClient/game/index.html'
    }
    if (request.headers['content-type']) headers['Content-Type'] = request.headers['content-type']
    if (request.headers['user-agent']) headers['User-Agent'] = request.headers['user-agent']
    if (request.headers['content-length']) headers['Content-Length'] = request.headers['content-length']

    let data = undefined
    if (request.body !== undefined && request.body !== null) {
      if (Buffer.isBuffer(request.body) || typeof request.body === 'string') {
        data = request.body
      } else if (typeof request.body === 'object') {
        data = JSON.stringify(request.body)
        if (!headers['Content-Type']) headers['Content-Type'] = 'application/json'
      }
    }

    try {
      const proxyResponse = await axios({
        method: request.method,
        url: `${baseUrl}${request.path}`,
        headers: { ...headers, ...this._passthroughRequestHeaders(request) },
        data,
        responseType: 'stream',
        decompress: false,
        timeout: 30000,
        validateStatus: () => true
      })
      this._pipeProxyResponse(proxyResponse, response)
    } catch (error) {
      console.error(`[Proxy] Error proxying to ${baseUrl}:`, error.message)
      if (!response.headersSent) {
        response.status(502).json({ error: 'Proxy error', message: error.message })
      }
    }
  }
}

module.exports = new FilesController();
module.exports.LATEST_SWF_FILE = LATEST_SWF_FILE
module.exports.PREVIOUS_LATEST_SWF_FILES = PREVIOUS_LATEST_SWF_FILES
