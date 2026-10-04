const path = require('path')

class InlinePluginManager {
  constructor(application) {
    this.application = application
    this._currentPlugin = null
    this._$listSection = null
    this._$pluginHeader = null
    this._$container = null
    this._$iframe = null
    this._$nameSpan = null
    this._packetListeners = new Set()
  }

  initialize() {
    this._$listSection = $('#pluginsSectionContent')
    this._$pluginHeader = $('#plugins > .flex.items-center.justify-between')
    this._$container = $('#inlinePluginContainer')
    this._$iframe = $('#inlinePluginFrame')
    this._$nameSpan = $('#inlinePluginName')

    $('#inlinePluginBackBtn').on('click', () => this.close())
    $('#inlinePluginPopoutBtn').on('click', () => this.popout())

    this._trackPacketListeners()
  }

  // Inline plugins subscribe with window.parent.addEventListener('jam-packet')
  // and rarely unsubscribe, so each open/close left a handler on this window
  // that pinned the dead iframe and still ran for every packet. The iframe is
  // the only jam-packet consumer here, so every such listener belongs to it.
  _trackPacketListeners() {
    const listeners = this._packetListeners
    const add = window.addEventListener
    const remove = window.removeEventListener

    window.addEventListener = function (type, listener, options) {
      if (type === 'jam-packet' && listener) listeners.add({ listener, options })
      return add.call(this, type, listener, options)
    }
    window.removeEventListener = function (type, listener, options) {
      if (type === 'jam-packet') {
        for (const entry of listeners) {
          if (entry.listener === listener) listeners.delete(entry)
        }
      }
      return remove.call(this, type, listener, options)
    }
    this._removePacketListener = (entry) => remove.call(window, 'jam-packet', entry.listener, entry.options)
  }

  _releasePacketListeners() {
    for (const entry of this._packetListeners) {
      this._removePacketListener(entry)
    }
    this._packetListeners.clear()
  }

  open(pluginName) {
    const plugin = this.application.dispatch.plugins.get(pluginName)
    if (!plugin) return

    const { filepath, configuration: { main } } = plugin
    const url = `file://${path.join(filepath, main)}`

    this._releasePacketListeners()
    this._currentPlugin = pluginName
    this._$nameSpan.text(pluginName)
    this._$listSection.addClass('hidden')
    this._$pluginHeader.addClass('hidden')
    this._$container.removeClass('hidden')
    this._$iframe.attr('src', url)

    this._$iframe.off('load').on('load', () => {
      this._injectJamBridge()
      if (window._pendingSpammerPacket && pluginName === 'Packet Spammer') {
        const packet = window._pendingSpammerPacket
        window._pendingSpammerPacket = null
        setTimeout(() => {
          try {
            const iframeWin = this._$iframe[0].contentWindow
            if (iframeWin && iframeWin.spammer && iframeWin.spammer.input) {
              iframeWin.spammer.input.value = packet
            } else if (iframeWin && iframeWin.document) {
              const input = iframeWin.document.getElementById('inputTxt')
              if (input) input.value = packet
            }
          } catch (e) {}
        }, 100)
      }
    })

    this.application.pluginUIManager.updatePluginStatusIndicator(pluginName, true)
  }

  close() {
    if (this._currentPlugin) {
      this.application.pluginUIManager.updatePluginStatusIndicator(this._currentPlugin, false)
    }
    this._$iframe.attr('src', 'about:blank')
    this._releasePacketListeners()
    this._$container.addClass('hidden')
    this._$listSection.removeClass('hidden')
    this._$pluginHeader.removeClass('hidden')
    this._currentPlugin = null
  }

  popout() {
    if (!this._currentPlugin) return
    const name = this._currentPlugin
    this.close()
    this.application.dispatch.open(name)
  }

  _injectJamBridge() {
    try {
      const iframeWin = this._$iframe[0].contentWindow
      if (!iframeWin) return

      if (!iframeWin.jQuery) {
        iframeWin.jQuery = iframeWin.$ = require('jquery')
      }

      const { ipcRenderer } = require('electron')
      const dispatch = this.application.dispatch
      const app = this.application
      const existingJam = iframeWin.jam || {}

      iframeWin.jam = Object.assign({}, existingJam, {
        isEmbedded: true,
        ipcRenderer,
        dispatch: {
          sendRemoteMessage: (msg, options) => dispatch.sendRemoteMessage(msg, options),
          sendConnectionMessage: (msg, options) => dispatch.sendConnectionMessage(msg, options),
          sendMultipleMessages: ({ type, messages = [] } = {}) => {
            const sendFn = type === 'aj'
              ? (msg) => dispatch.sendRemoteMessage(msg)
              : (msg) => dispatch.sendConnectionMessage(msg)
            for (const msg of messages) {
              sendFn(msg)
            }
          },
          getState: (key) => dispatch.getState(key),
          getStateSync: (key) => dispatch.getStateSync(key),
          getConnectedClients: () => dispatch.getConnectedClients(),
          runInBackground: false
        },
        onPacket: existingJam.onPacket || null,
        showToast: (message, type) => app.consoleMessage({ type: type || 'notify', message }),
        application: {
          consoleMessage: (type, msg) => app.consoleMessage({ type, message: msg })
        },
        readJsonFile: existingJam.readJsonFile || async function(filePath, defaultValue = null) {
          try {
            return await ipcRenderer.invoke('read-json-file', filePath, defaultValue)
          } catch (e) {
            return defaultValue
          }
        },
        writeJsonFile: existingJam.writeJsonFile || async function(filePath, data) {
          try {
            return await ipcRenderer.invoke('write-json-file', filePath, data)
          } catch (e) {
            return false
          }
        }
      })

      const embeddedLink = iframeWin.document.createElement('link')
      embeddedLink.rel = 'stylesheet'
      embeddedLink.href = 'app://assets/styles/plugin-embedded.css'
      iframeWin.document.head.appendChild(embeddedLink)

      iframeWin.close = () => {}

      iframeWin.dispatchEvent(new CustomEvent('jam-ready'))
    } catch (err) {
      console.error('Failed to inject jam bridge:', err)
    }
  }
}

module.exports = InlinePluginManager
