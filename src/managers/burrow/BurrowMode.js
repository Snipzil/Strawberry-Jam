const GameServerTarget = require('../../services/network/GameServerTarget')

/**
 * Plugins that only make sense on Animal Jam, hidden while Burrow mode is on,
 * with the reason shown in their place.
 * @type {Object<string, string>}
 */
const AJ_ONLY_PLUGINS = Object.freeze({
  'Auto Redeemer': 'Burrow has no Animal Jam codes to redeem',
  'Gem Farm': 'Burrow tops up every currency at each login',
  'TFD Automation': "Burrow doesn't have The Forgotten Desert",
  'Tiki Trouble Automation': "Burrow doesn't have Tiki Trouble",
  'Price Checker': 'Prices are Animal Jam trade values',
  Membership: 'Burrow accounts are members already',
  'Membership Tracker': 'Burrow accounts are members already',
  'Username Logger': 'It checks Animal Jam accounts'
})

const STATUS_INTERVAL_MS = 60000

/**
 * Burrow mode: the launcher plays on a Burrow AJ Classic private server
 * (https://github.com/burrow-dev/burrow-server) instead of Animal Jam.
 *
 * The choice is GameServerTarget's file, which the proxy, the API's asset
 * proxy and the game client's login screen read; this switches it, keeps the
 * header switch and status bar in step, and hides the plugins that only work
 * on Animal Jam.
 *
 * @module BurrowMode
 */
class BurrowMode {
  constructor (application) {
    this.application = application
    this._statusTimer = null
  }

  /** @returns {{server: string, url: string, client: string}} */
  get target () {
    return GameServerTarget.read()
  }

  get active () {
    return this.target.server === 'burrow'
  }

  /** Why a plugin is hidden in Burrow mode, or null when it isn't. */
  hiddenReason (pluginName) {
    return this.active && Object.prototype.hasOwnProperty.call(AJ_ONLY_PLUGINS, pluginName)
      ? AJ_ONLY_PLUGINS[pluginName]
      : null
  }

  /**
   * Checks that `url` is a Burrow server.
   * @returns {Promise<Object>} its flashvars
   */
  async probe (url) {
    const flashVars = await GameServerTarget.getJson(`${url}/flashvars`)
    if (!flashVars || !flashVars.clientURL || !flashVars.smartfoxPort) {
      throw new Error(`${url} is not a Burrow server`)
    }
    return flashVars
  }

  /**
   * "play.burrow.moe" -> "https://play.burrow.moe". The password and login
   * token go to this address, so only a server on this computer may skip
   * https (as in Burrow's own client).
   */
  normalizeUrl (text) {
    let value = String(text || '').trim() || GameServerTarget.DEFAULT_BURROW_URL
    if (!/^https?:\/\//i.test(value)) value = `https://${value}`
    let url
    try {
      url = new URL(value)
    } catch (_) {
      throw new Error('That is not a valid address.')
    }
    if (url.protocol === 'http:' && !['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname)) {
      throw new Error('Use an https:// address (http:// is only for a server on this computer).')
    }
    return url.origin
  }

  /**
   * Switches the launcher to Burrow (true) or Animal Jam (false).
   * @param {boolean} on
   * @param {{url?: string, client?: string}} [options]
   */
  async setActive (on, options = {}) {
    const changes = { server: on ? 'burrow' : 'animaljam' }
    if (options.url !== undefined) changes.url = this.normalizeUrl(options.url)
    if (options.client !== undefined) changes.client = options.client === 'burrow' ? 'burrow' : 'strawberry'
    if (on) await this.probe(changes.url || this.target.url)
    const target = GameServerTarget.write(changes)

    this.application.consoleMessage({
      type: 'success',
      message: on
        ? `Burrow mode on: playing on ${new URL(target.url).host}.${this.application._isGameRunning ? ' Log out of the game and back in to switch.' : ''}`
        : `Burrow mode off: playing on Animal Jam.${this.application._isGameRunning ? ' Log out of the game and back in to switch.' : ''}`
    })
    this.apply()
    return target
  }

  /** Saves the server address and game client without switching modes. */
  async configure ({ url, client } = {}) {
    const changes = {}
    if (url !== undefined) changes.url = this.normalizeUrl(url)
    if (client !== undefined) changes.client = client === 'burrow' ? 'burrow' : 'strawberry'
    if (changes.url && this.active) await this.probe(changes.url)
    const target = GameServerTarget.write(changes)
    this.apply()
    return target
  }

  // the header's AJ / Burrow switch
  _bindSwitch () {
    const group = document.getElementById('serverSwitch')
    if (!group || this._switchBound) return
    this._switchBound = true
    group.addEventListener('click', async event => {
      const button = event.target.closest('[data-server]')
      if (!button) return
      const wantBurrow = button.dataset.server === 'burrow'
      if (wantBurrow === this.active) return
      group.classList.add('busy')
      try {
        await this.setActive(wantBurrow)
      } catch (err) {
        this.application.consoleMessage({ type: 'error', message: `Couldn't switch to Burrow: ${err.message}` })
      } finally {
        group.classList.remove('busy')
      }
    })
  }

  /** Brings the header switch, status bar and plugin list in step with the mode. */
  apply () {
    this._bindSwitch()
    const active = this.active
    const target = this.target
    document.body.classList.toggle('burrow-mode', active)

    for (const button of document.querySelectorAll('#serverSwitch [data-server]')) {
      const selected = (button.dataset.server === 'burrow') === active
      button.classList.toggle('active', selected)
      button.setAttribute('aria-pressed', String(selected))
    }
    const play = document.getElementById('playGameBtn')
    if (play) play.title = active ? `Launch Game on Burrow (${new URL(target.url).host})` : 'Launch Game'

    if (this.application.pluginUIManager && this.application.pluginUIManager.reorderPluginList) {
      this.application.pluginUIManager.reorderPluginList()
    }

    clearInterval(this._statusTimer)
    this._statusTimer = null
    if (active) {
      this.checkStatus()
      this._statusTimer = setInterval(() => this.checkStatus(), STATUS_INTERVAL_MS)
    } else if (this.application.connectionStatusManager) {
      this.application.connectionStatusManager.checkServerStatus().catch(() => {})
    }
  }

  /** The status bar: how many are playing on the Burrow server. */
  async checkStatus () {
    const element = document.getElementById('connection-status')
    if (!element || !this.active) return
    const dot = element.querySelector('span:first-child')
    const label = element.querySelector('span:last-child')
    const set = (text, colour, title) => {
      element.style.display = ''
      dot.classList.remove('bg-error-red', 'bg-highlight-green', 'bg-highlight-yellow', 'bg-tertiary-bg', 'pulse-animation', 'pulse-yellow', 'pulse-loading', 'pulse-green')
      element.classList.remove('text-highlight-green', 'text-gray-400', 'text-highlight-yellow', 'text-error-red')
      dot.classList.add(colour === 'green' ? 'bg-highlight-green' : 'bg-error-red', colour === 'green' ? 'pulse-green' : 'pulse-animation')
      element.classList.add(colour === 'green' ? 'text-highlight-green' : 'text-error-red')
      label.textContent = text
      element.setAttribute('title', title)
    }
    const url = this.target.url
    try {
      const status = await GameServerTarget.getJson(`${url}/api/status`)
      if (!this.active) return
      const online = Number(status.online) || 0
      set(`Burrow: ${online} playing`, 'green', `${new URL(url).host} is up (${online} online)`)
    } catch (err) {
      if (!this.active) return
      set('Burrow: Unreachable', 'red', `${url}: ${err.message}`)
    }
  }
}

module.exports = BurrowMode
module.exports.AJ_ONLY_PLUGINS = AJ_ONLY_PLUGINS
