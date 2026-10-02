const { autoUpdater } = require('electron-updater');
const logManager = require('../../utils/LogManager');
const processManager = require('../../utils/ProcessManager');

const STARTUP_CHECK_DELAY_MS = 10 * 1000;
const CHECK_INTERVAL_MS = 30 * 60 * 1000;
// Backoff after a failed check or download, then back to the normal interval.
const RETRY_DELAYS_MS = [2 * 60 * 1000, 5 * 60 * 1000, 15 * 60 * 1000];
// Progress events fire many times a second; the UI only needs a few.
const PROGRESS_THROTTLE_MS = 250;

const RELEASES_URL = 'https://github.com/Snipzil/Strawberry-Jam/releases/latest';

/**
 * Owns the app's update lifecycle in the main process. Every state change is
 * pushed to the main window on `app-update-status`, so the header indicator,
 * the console and the Settings panel all show the same thing whether the check
 * was automatic or manual.
 *
 * status: idle | disabled | checking | up-to-date | available | downloading |
 *         downloaded | installing | error
 */
class AutoUpdateService {
  constructor(app, store, window) {
    this.app = app;
    this.store = store;
    this.window = window;
    this.timerId = null;
    this.retryIndex = 0;
    this.lastProgressSentAt = 0;
    this.initialized = false;
    this.state = {
      status: 'idle',
      currentVersion: app ? app.getVersion() : null,
      version: null,
      percent: null,
      bytesPerSecond: null,
      transferred: null,
      total: null,
      error: null,
      // 'check' or 'download': lets the UI tell a failed background check
      // (quiet) from a failed download of a known update (worth showing).
      errorPhase: null,
      autoDownload: this.isAutoDownloadEnabled(),
      lastCheckedAt: store ? store.get('updates.lastAutoCheckAt', null) : null,
      releasesUrl: RELEASES_URL
    };
  }

  isAutoDownloadEnabled() {
    return this.store ? this.store.get('updates.enableAutoUpdates', true) !== false : true;
  }

  getState() {
    return { ...this.state };
  }

  _send() {
    const win = this.window;
    if (win && !win.isDestroyed() && win.webContents && !win.webContents.isDestroyed()) {
      win.webContents.send('app-update-status', this.getState());
    }
  }

  _setState(patch) {
    this.state = { ...this.state, ...patch };
    try {
      this.store.set('updates.lastAutoCheckStatus', this.state.status);
      this.store.set('updates.lastAutoCheckMeta', {
        version: this.state.version,
        error: this.state.error,
        errorPhase: this.state.errorPhase
      });
    } catch (e) {
    }
    this._send();
  }

  _schedule(delayMs) {
    if (this.timerId) clearTimeout(this.timerId);
    this.timerId = setTimeout(() => {
      this.timerId = null;
      this.checkNow().catch(() => {});
    }, delayMs);
  }

  _scheduleRetry() {
    const delay = RETRY_DELAYS_MS[Math.min(this.retryIndex, RETRY_DELAYS_MS.length - 1)];
    this.retryIndex += 1;
    this._schedule(delay);
    return delay;
  }

  initialize() {
    if (this.initialized) return;
    this.initialized = true;

    if (!this.app.isPackaged) {
      try {
        logManager.info('Skipping auto-updater initialization in development mode', 'auto-update');
      } catch (e) {
      }
      this._setState({ status: 'disabled' });
      return;
    }

    autoUpdater.logger = {
      debug: (m) => logManager.debug(String(m), 'auto-update'),
      info: (m) => logManager.info(String(m), 'auto-update'),
      warn: (m) => logManager.warn(String(m), 'auto-update'),
      error: (m) => logManager.error(String(m), 'auto-update')
    };
    autoUpdater.autoDownload = this.isAutoDownloadEnabled();
    autoUpdater.autoInstallOnAppQuit = true;
    autoUpdater.allowDowngrade = false;
    autoUpdater.allowPrerelease = false;

    autoUpdater.on('checking-for-update', () => {
      this._setState({ status: 'checking', error: null, errorPhase: null });
    });

    autoUpdater.on('update-not-available', () => {
      const now = new Date().toISOString();
      try {
        this.store.set('updates.lastAutoCheckAt', now);
      } catch (e) {
      }
      this.retryIndex = 0;
      this._setState({ status: 'up-to-date', version: null, lastCheckedAt: now });
      this._schedule(CHECK_INTERVAL_MS);
    });

    autoUpdater.on('update-available', (info) => {
      const now = new Date().toISOString();
      try {
        this.store.set('updates.lastAutoCheckAt', now);
      } catch (e) {
      }
      this.retryIndex = 0;
      const version = info && info.version ? info.version : null;
      logManager.info(`Update available ${version || ''}`.trim(), 'auto-update');
      this._setState({
        status: autoUpdater.autoDownload ? 'downloading' : 'available',
        version,
        percent: autoUpdater.autoDownload ? 0 : null,
        lastCheckedAt: now
      });
      // With auto-download off, keep checking so a newer release replaces
      // the one we're offering.
      if (!autoUpdater.autoDownload) this._schedule(CHECK_INTERVAL_MS);
    });

    autoUpdater.on('download-progress', (progress) => {
      const now = Date.now();
      if (progress.percent < 100 && now - this.lastProgressSentAt < PROGRESS_THROTTLE_MS) return;
      this.lastProgressSentAt = now;
      this._setState({
        status: 'downloading',
        percent: progress.percent,
        bytesPerSecond: progress.bytesPerSecond,
        transferred: progress.transferred,
        total: progress.total
      });
    });

    autoUpdater.on('update-downloaded', (info) => {
      const version = info && info.version ? info.version : this.state.version;
      logManager.info(`Update downloaded ${version || ''}`.trim(), 'auto-update');
      this.retryIndex = 0;
      if (this.timerId) clearTimeout(this.timerId);
      this.timerId = null;
      this._setState({ status: 'downloaded', version, percent: 100, error: null, errorPhase: null });
    });

    autoUpdater.on('error', (err) => {
      const message = err && err.message ? err.message : String(err);
      const phase = this.state.status === 'downloading' ? 'download' : 'check';
      logManager.error(`Auto-updater error (${phase}): ${message}`, 'auto-update');
      const retryInMs = this._scheduleRetry();
      // A failed re-check shouldn't hide an update the user can already download.
      if (phase === 'check' && this.state.status === 'available') return;
      this._setState({
        status: 'error',
        error: message,
        errorPhase: phase,
        percent: null,
        retryAt: new Date(Date.now() + retryInMs).toISOString()
      });
    });

    if (typeof this.store.onDidChange === 'function') {
      this.store.onDidChange('updates.enableAutoUpdates', (next) => {
        const enabled = next !== false;
        if (enabled === autoUpdater.autoDownload) return;
        autoUpdater.autoDownload = enabled;
        this._setState({ autoDownload: enabled });
        if (enabled && this.state.status === 'available') this.downloadNow().catch(() => {});
      });
    }

    this._schedule(STARTUP_CHECK_DELAY_MS);
  }

  /**
   * Checks for an update now. Safe to call at any time: it's a no-op while a
   * check or download is running or an update is already waiting to install.
   */
  async checkNow() {
    if (!this.initialized || this.state.status === 'disabled') {
      this._send();
      return this.getState();
    }
    if (['checking', 'downloading', 'downloaded', 'installing'].includes(this.state.status)) {
      this._send();
      return this.getState();
    }
    try {
      await autoUpdater.checkForUpdates();
    } catch (e) {
      // Reported through the 'error' event.
    }
    return this.getState();
  }

  async downloadNow() {
    if (!this.initialized || this.state.status === 'disabled') return this.getState();
    if (['downloading', 'downloaded', 'installing'].includes(this.state.status)) return this.getState();
    if (!this.state.version) {
      // Nothing known to download yet (or the failed attempt was a check).
      return this.checkNow();
    }
    this._setState({ status: 'downloading', percent: 0, error: null, errorPhase: null });
    try {
      await autoUpdater.downloadUpdate();
    } catch (e) {
      // Reported through the 'error' event.
    }
    return this.getState();
  }

  /**
   * Closes the game and helper processes, then installs silently and
   * relaunches. Killing children first avoids the installer racing a
   * still-running client for locked files.
   */
  async installNow() {
    if (this.state.status !== 'downloaded') return false;
    this._setState({ status: 'installing' });
    logManager.info(`Installing update ${this.state.version || ''}`.trim(), 'auto-update');
    try {
      await processManager.killAll(null);
    } catch (e) {
    }
    setImmediate(() => {
      try {
        autoUpdater.quitAndInstall(true, true);
      } catch (e) {
        logManager.error(`quitAndInstall failed: ${e.message}`, 'auto-update');
        this._setState({ status: 'downloaded' });
      }
    });
    return true;
  }

  getDiagnosticsSnapshot() {
    return {
      ...this.getState(),
      enableAutoUpdates: this.isAutoDownloadEnabled(),
      lastAutoCheckAt: this.store.get('updates.lastAutoCheckAt', null),
      lastAutoCheckStatus: this.store.get('updates.lastAutoCheckStatus', null),
      lastAutoCheckMeta: this.store.get('updates.lastAutoCheckMeta', null),
      autoDownload: autoUpdater.autoDownload,
      allowPrerelease: autoUpdater.allowPrerelease,
      allowDowngrade: autoUpdater.allowDowngrade,
      updateConfigPath: autoUpdater.updateConfigPath || null
    };
  }

  dispose() {
    if (this.timerId) {
      clearTimeout(this.timerId);
      this.timerId = null;
    }
  }
}

module.exports = AutoUpdateService;
