/**
 * @file path-utils.js - Path management utilities for Username Logger
 * @author glvckoma
 */

const path = require('path');
const fs = require('fs');
const {
  COLLECTED_USERNAMES_FILE,
  POTENTIAL_ACCOUNTS_FILE,
  PROCESSED_FILE,
  FOUND_GENERAL_FILE,
  FOUND_AJC_FILE,
  FOUND_NOPASS_FILE
} = require('../constants/constants');

/**
 * Determines the base path for all Username Logger files.
 * This path is now the dedicated 'UsernameLogger' directory within the app's roaming data folder.
 * @param {string} pluginStoragePath - The dedicated storage path for the plugin (e.g., .../strawberry-jam/UsernameLogger).
 * @returns {string} The base path for Username Logger files.
 */
function getBasePath(pluginStoragePath) {
  if (!pluginStoragePath) {
    console.error("[Username Logger] Error: getBasePath called without pluginStoragePath!");
    // Provide a fallback path to prevent crashes, though this indicates a severe issue.
    return path.resolve('.', 'username_logger_data_error');
  }
  // The calling context is now responsible for ensuring this directory exists.
  return pluginStoragePath;
}

/**
 * Gets file paths, all centralized within the plugin's dedicated storage directory.
 * @param {string} pluginStoragePath - The plugin's dedicated storage path (e.g., .../strawberry-jam/UsernameLogger).
 * @returns {Object} An object containing all necessary file paths.
 */
function getFilePaths(pluginStoragePath) {
  // All files now use the same centralized base path.
  const basePath = getBasePath(pluginStoragePath);

  const paths = {
    collectedUsernamesPath: path.join(basePath, COLLECTED_USERNAMES_FILE),
    processedUsernamesPath: path.join(basePath, PROCESSED_FILE),
    potentialAccountsPath: path.join(basePath, POTENTIAL_ACCOUNTS_FILE),
    foundAccountsPath: path.join(basePath, FOUND_GENERAL_FILE),
    ajcAccountsPath: path.join(basePath, FOUND_AJC_FILE),
    foundNoPassPath: path.join(basePath, FOUND_NOPASS_FILE)
    // workingAccountsPath has been removed as it is deprecated.
  };

  return paths;
}

/**
 * Ensures a directory exists, creating it if necessary.
 * @param {string} dirPath - The path to check/create
 * @returns {boolean} True if directory exists or was created, false if creation failed
 */
function ensureDirectoryExists(dirPath) {
  try {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
    return true;
  } catch (error) {
    console.error(`[Username Logger] Error creating directory ${dirPath}: ${error.message}`);
    return false;
  }
}

module.exports = {
  getBasePath,
  getFilePaths,
  ensureDirectoryExists
};
