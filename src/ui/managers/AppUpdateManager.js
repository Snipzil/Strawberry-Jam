const { ipcRenderer } = require('electron')

const formatBytes = (bytes) => {
  if (!bytes || bytes <= 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB']
  const i = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1)
  return `${(bytes / Math.pow(1024, i)).toFixed(i === 0 ? 0 : 1)} ${units[i]}`
}

const minutesUntil = (iso) => {
  if (!iso) return null
  const ms = new Date(iso).getTime() - Date.now()
  return ms > 0 ? Math.max(1, Math.round(ms / 60000)) : null
}

/**
 * AppUpdateManager - Shows the app's update status everywhere it matters:
 * a header pill (progress, then "Restart to update"), console messages at
 * each step, a desktop notification when an update is ready while the window
 * is in the background, and a feed for the Settings panel.
 *
 * State comes from AutoUpdateService in the main process on `app-update-status`.
 *
 * @module AppUpdateManager
 */
class AppUpdateManager {
  constructor (application) {
    this.application = application
    this.state = null
    this._listeners = new Set()
    // "<status>:<version>" pairs already announced, so each step is posted once.
    this._announced = new Set()
    this.$pill = null
  }

  async initialize () {
    this.$pill = document.getElementById('appUpdateBtn')
    if (this.$pill) {
      this.$pill.addEventListener('click', () => this._onPillClick())
    }

    ipcRenderer.on('app-update-status', (event, state) => this._apply(state))

    try {
      const state = await ipcRenderer.invoke('get-update-status')
      if (state) this._apply(state)
    } catch (e) {
    }
  }

  /**
   * Calls `listener(state)` now and on every change.
   * @returns {Function} unsubscribe
   */
  subscribe (listener) {
    this._listeners.add(listener)
    if (this.state) listener(this.state)
    return () => this._listeners.delete(listener)
  }

  checkNow () {
    ipcRenderer.send('check-for-updates')
  }

  downloadNow () {
    ipcRenderer.send('download-update')
  }

  installNow () {
    return ipcRenderer.invoke('install-update')
  }

  _apply (state) {
    const previous = this.state
    this.state = state
    this._renderPill()
    this._announce(previous, state)
    this._listeners.forEach(listener => {
      try {
        listener(state)
      } catch (e) {
      }
    })
  }

  _onPillClick () {
    const state = this.state
    if (!state) return
    switch (state.status) {
      case 'available':
        this.downloadNow()
        break
      case 'downloaded':
        this.installNow()
        break
      case 'error':
        this.downloadNow()
        break
      default:
        break
    }
  }

  _renderPill () {
    const $pill = this.$pill
    if (!$pill) return
    const { status, version, percent, bytesPerSecond, transferred, total, errorPhase } = this.state
    const v = version ? `v${version}` : ''

    let mode = null
    let label = ''
    let tooltip = ''
    switch (status) {
      case 'available':
        mode = 'available'
        label = `Update ${v}`.trim()
        tooltip = `Strawberry Jam ${v} is available. Click to download it.`
        break
      case 'downloading': {
        const pct = Math.floor(percent || 0)
        mode = 'downloading'
        label = `Updating ${pct}%`
        tooltip = total
          ? `Downloading ${v}: ${formatBytes(transferred)} of ${formatBytes(total)}${bytesPerSecond ? ` (${formatBytes(bytesPerSecond)}/s)` : ''}`
          : `Downloading ${v}...`
        $pill.style.setProperty('--update-pct', `${pct}%`)
        break
      }
      case 'downloaded':
        mode = 'ready'
        label = 'Restart to update'
        tooltip = `${v} is ready. Click to restart and install it now, or it installs the next time you close Strawberry Jam.`
        break
      case 'installing':
        mode = 'ready'
        label = 'Restarting...'
        tooltip = 'Installing the update.'
        break
      case 'error':
        // A failed background check isn't worth a header alert; a failed
        // download of a known update is.
        if (errorPhase === 'download') {
          mode = 'error'
          label = 'Update failed'
          tooltip = `Couldn't download ${v}. Click to retry now, or get it from the GitHub releases page.`
        }
        break
      default:
        break
    }

    if (!mode) {
      $pill.style.display = 'none'
      return
    }
    $pill.style.display = ''
    $pill.dataset.mode = mode
    $pill.disabled = status === 'installing'
    $pill.setAttribute('data-tooltip', tooltip)
    $pill.setAttribute('aria-label', tooltip)
    const $label = $pill.querySelector('.app-update-label')
    if ($label) $label.textContent = label
  }

  _announce (previous, state) {
    const app = this.application
    if (!app || typeof app.consoleMessage !== 'function') return
    const key = `${state.status}:${state.version || ''}`
    const changed = !previous || previous.status !== state.status || previous.version !== state.version
    if (!changed || this._announced.has(key)) return

    const v = state.version ? `v${state.version}` : 'An update'
    switch (state.status) {
      case 'available':
        this._announced.add(key)
        app.consoleMessage({
          type: 'notify',
          message: `Strawberry Jam ${v} is available. Click "Update" at the top of the window to download it.`
        })
        break
      case 'downloading':
        this._announced.add(key)
        app.consoleMessage({ type: 'notify', message: `Downloading Strawberry Jam ${v}...` })
        break
      case 'downloaded':
        this._announced.add(key)
        app.consoleMessage({
          type: 'success',
          message: `Strawberry Jam ${v} is ready. Click "Restart to update" at the top of the window, or it installs the next time you close the app.`
        })
        this._notifyDesktop(state)
        break
      case 'error': {
        if (state.errorPhase !== 'download') return
        this._announced.add(key)
        const mins = minutesUntil(state.retryAt)
        app.consoleMessage({
          type: 'error',
          message: `Couldn't download Strawberry Jam ${v}: ${state.error}. ${mins ? `Retrying in ${mins} min. ` : ''}You can also download it from ${state.releasesUrl}`
        })
        break
      }
      default:
        break
    }
  }

  _notifyDesktop (state) {
    if (document.hasFocus()) return
    try {
      const notification = new Notification('Strawberry Jam update ready', {
        body: `v${state.version} has downloaded. Restart Strawberry Jam to install it.`,
        silent: true
      })
      notification.onclick = () => window.focus()
    } catch (e) {
    }
  }
}

module.exports = AppUpdateManager
