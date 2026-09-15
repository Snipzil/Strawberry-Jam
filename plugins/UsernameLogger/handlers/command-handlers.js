/**
 * @file command-handlers.js - Command handlers for Username Logger
 * @author glvckoma
 */

/**
 * Class for handling user commands
 */
class CommandHandlers {
  /**
   * Creates a new command handlers instance
   * @param {Object} options - Handler options
   * @param {Object} options.application - The application object for logging
   * @param {Object} options.configModel - The config model for configuration
   * @param {Object} options.stateModel - The state model for state management
   * @param {Object} options.fileService - The file service for file operations
   * @param {Object} options.apiService - The API service for API operations
   * @param {Object} options.leakCheckService - The leak check service for leak checking
   * @param {string} options.pluginStoragePath - The dedicated storage path for the plugin
   */
  constructor({ application, configModel, stateModel, fileService, apiService, leakCheckService, pluginStoragePath }) {
    this.application = application;
    this.configModel = configModel;
    this.stateModel = stateModel;
    this.fileService = fileService;
    this.apiService = apiService;
    this.leakCheckService = leakCheckService;
    this.pluginStoragePath = pluginStoragePath;
    
    // Bind methods to ensure 'this' context is correct
    this.handleLeakCheckCommand = this.handleLeakCheckCommand.bind(this);
    this.handleLeakCheckStopCommand = this.handleLeakCheckStopCommand.bind(this);
  }

  /**
   * Detect whether we're in development mode - more reliable than process.env.NODE_ENV
   * @returns {boolean} true if in development mode
   * @private
   */
  _isDevMode() {
    try {
      // In packaged apps, app.asar will be in the path
      return !window.location.href.includes('app.asar');
    } catch (e) {
      return false;
    }
  }

  /**
   * Handles the leak check command.
   * @param {Object} params - Command parameters.
   * @param {string[]} params.parameters - Command arguments.
   */
  async handleLeakCheckCommand({ parameters }) {
    try {
      // Always resume from the last processed index by default
      let limit = Infinity;
      const startIndex = this.configModel.getLeakCheckIndex() + 1;
      
      // Build a refined start message and show it with a removable messageId
      const fromText = startIndex <= 0 ? 'from the beginning' : 'from where you left off';
      let startMessageText;
      if (parameters.length > 0 && parameters[0].toLowerCase() !== 'all') {
        // Numeric limit provided
        const num = parseInt(parameters[0], 10);
        if (isNaN(num) || num <= 0) {
          this.application.consoleMessage({ type: 'error', message: `[Username Logger] Invalid parameter. Use a positive number or 'all'.` });
          return;
        }
        limit = num;
        startMessageText = `[Username Logger] Processing up to ${limit} usernames ${fromText}.`;
      } else {
        // 'all' or no parameter
        startMessageText = `[Username Logger] Processing all remaining usernames ${fromText}.`;
      }

      const startMessageId = `leakcheck-start-${Date.now()}`;
      this.application.consoleMessage({ type: 'notify', message: startMessageText, details: { messageId: startMessageId } });
      
      // Run the leak check with the determined parameters and pass message IDs for cleanup
      this.leakCheckService.runLeakCheck({ limit, startIndex, context: { startMessageId } });
    } catch (error) {
      // Silent error handling to avoid breaking the app
      this.application.consoleMessage({
        type: 'error',
        message: `[Username Logger] Error starting leak check: ${error.message}`
      });
    }
  }

  /**
   * Handles the leak check stop command.
   */
  handleLeakCheckStopCommand() {
    try {
      this.leakCheckService.stopLeakCheck();
    } catch (error) {
      // Silent error handling
      this.application.consoleMessage({
        type: 'error',
        message: `[Username Logger] Error stopping leak check: ${error.message}`
      });
    }
  }

  /**
   * Registers all command handlers with the dispatch system
   * @param {Object} dispatch - The dispatch system
   */
  registerHandlers(dispatch) {
    try {
      dispatch.onCommand({
        name: 'leakcheck',
        description: 'Run a leak check on collected usernames. Usage: !leakcheck [all|number]',
        callback: this.handleLeakCheckCommand
      });

      dispatch.onCommand({
        name: 'leakcheckstop',
        description: 'Stop a running leak check.',
        callback: this.handleLeakCheckStopCommand
      });
  
      
    } catch (error) {
      console.error('[Username Logger] Error registering command handlers:', error);
    }
  }
}

module.exports = CommandHandlers;
