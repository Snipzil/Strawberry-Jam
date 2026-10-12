/**
 * Server Status Checker Service
 * Handles checking Animal Jam server availability by mimicking actual game authentication
 */

const HttpClient = require('./HttpClient');

// Public SmartFox load balancers the client is assigned to.
const GAME_SERVER_HOSTS = ['lb-iss01-classic-prod.animaljam.com', 'lb-iss02-classic-prod.animaljam.com'];

class ServerStatusChecker {
  /**
   * Check if Animal Jam servers are online by attempting authentication
   * This mimics the actual game login process to get accurate status
   * @param {string} serverHost - The server host to check (defaults to lb-iss02-classic-prod.animaljam.com)
   * @returns {Promise<{isOnline: boolean, responseTime: number, timestamp: number, server: string, accessStatus: string, statusCode: number|null, details: string}>} Status result
   */
  static async checkServerStatus(serverHost = 'lb-iss02-classic-prod.animaljam.com') {
    const result = {
      isOnline: false,
      responseTime: 0,
      timestamp: Date.now(),
      server: serverHost,
      accessStatus: 'unknown', // 'unknown', 'ok', 'blocked', 'rate_limited', 'auth_error', 'network_error', 'server_error'
      statusCode: null,
      details: ''
    };
    
    try {
      const startTime = performance.now();
      
      // Use the same authentication endpoint as the actual game
      const authEndpoint = 'https://authenticator.animaljam.com/authenticate';
      
      // Create a request that mimics the actual game authentication
      // We use intentionally invalid credentials to test server response
      const authRequest = {
        domain: 'flash',
        username: 'test_user_' + Math.random().toString(36).substr(2, 9), // Random invalid username
        password: 'invalid_password_' + Math.random().toString(36).substr(2, 9), // Random invalid password
        df: this.generateRandomDF() // Generate a random DF like the game would
      };
      
      const options = {
        url: authEndpoint,
        timeout: 8000, // 8 second timeout (longer than before since auth is slower)
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) AJClassic/1.5.7 Chrome/87.0.4280.141 Electron/11.5.0 Safari/537.36',
          'Origin': 'https://www.animaljam.com',
          'Referer': 'https://www.animaljam.com/game/play'
        },
        body: JSON.stringify(authRequest),
        resolveWithFullResponse: true,
        simple: false // Don't throw on non-2xx responses
      };
      
      // Make the authentication request
      const response = await HttpClient.post(options);
      const endTime = performance.now();
      
      result.responseTime = Math.round(endTime - startTime);
      result.statusCode = response.statusCode;
      
      // Analyze the response based on actual game authentication logic
      if (response.statusCode === 401) {
        // Authentication failed - this is actually GOOD news for server status
        // It means the server is online and processing authentication requests
        result.isOnline = true;
        
        try {
          // axios has usually parsed the JSON already
          const errorData = typeof response.body === 'string' ? JSON.parse(response.body) : response.body;
          const errorCode = errorData.error_code;
          
          // Map error codes like the actual game does
          switch (errorCode) {
            case 101: // WRONG_CREDENTIALS - Expected with our invalid test credentials
              result.accessStatus = 'ok';
              result.details = 'Servers online - Authentication service responding normally';
              break;
            case 102: // BANNED
              result.accessStatus = 'ok'; // Server is up, just this specific request is banned
              result.details = 'Servers online - Test request was banned (normal behavior)';
              break;
            case 103: // SUSPENDED  
              result.accessStatus = 'ok'; // Server is up, just this specific request is suspended
              result.details = 'Servers online - Test request was suspended (normal behavior)';
              break;
            default:
              result.accessStatus = 'auth_error';
              result.details = `Authentication service returned error code: ${errorCode}`;
          }
        } catch (parseError) {
          // If we can't parse the error, but got a 401, server is likely up
          result.accessStatus = 'ok';
          result.details = 'Servers online - Authentication service responding (unparseable error)';
        }
      }
      else if (response.statusCode === 402 || response.statusCode === 403) {
        // Payment required or Forbidden - likely IP blocked
        result.isOnline = true;
        result.accessStatus = 'blocked';
        result.details = 'Servers online but your IP appears to be blocked';
      }
      else if (response.statusCode === 422) {
        // Unprocessable request - server is online but request was malformed
        result.isOnline = true;
        result.accessStatus = 'ok';
        result.details = 'Servers online - Request was unprocessable (expected with test data)';
      }
      else if (response.statusCode === 429) {
        // Too Many Requests - clear rate limiting
        result.isOnline = true;
        result.accessStatus = 'rate_limited';
        result.details = 'Servers online but rate limiting requests';
      }
      else if (response.statusCode === 503) {
        // Service Unavailable - could be down OR rate limited, treat as potentially down
        result.isOnline = false;
        result.accessStatus = 'server_error';
        result.details = 'Authentication service unavailable - servers may be down or under maintenance';
      }
      else if (response.statusCode === 200) {
        // Unexpected success with invalid credentials - should not happen
        result.isOnline = true;
        result.accessStatus = 'unusual';
        result.details = 'Servers online but authentication behaved unexpectedly';
      }
      else if (response.statusCode >= 500) {
        // Server errors indicate the authentication service is having issues
        result.isOnline = false;
        result.accessStatus = 'server_error';
        result.details = `Authentication servers experiencing errors (HTTP ${response.statusCode})`;
      }
      else {
        // Other status codes - be conservative and assume server issues
        result.isOnline = false;
        result.accessStatus = 'server_error';
        result.details = `Authentication service returned unexpected status: HTTP ${response.statusCode}`;
      }
      
      // If we successfully determined status from auth endpoint, try to get actual server info
      if (result.isOnline && result.accessStatus === 'ok') {
        try {
          // Try to get the actual server assignment (this might fail, which is okay)
          const serverInfo = await this.getServerInfo(serverHost);
          if (serverInfo) {
            result.server = serverInfo;
          }
        } catch (serverInfoError) {
          // Ignore errors getting server info - we already know servers are up
        }
        // The login service answering doesn't mean the game servers are up:
        // on 2026-10-12 it was fine while lb-iss02 dropped every connection.
        await this.applyGameServerStatus(result, serverHost);
      }
      
    } catch (error) {
      // Network or connection error
      result.isOnline = false;
      result.accessStatus = 'network_error';
      result.details = `Cannot connect to Animal Jam authentication servers: ${error.message}`;
      
      // Try the fallback check to the game server directly
      try {
        const fallbackResult = await this.fallbackServerCheck(serverHost);
        return fallbackResult;
      } catch (fallbackError) {
        // Both primary and fallback failed
        result.details += ` (Fallback also failed: ${fallbackError.message})`;
      }
    }
    
    return result;
  }
  
  /**
   * Generate a random DF (device fingerprint) like the game does
   * @returns {string} Random DF string
   * @private
   */
  static generateRandomDF() {
    // Generate a UUID-like string that mimics the game's DF format
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
  
  /**
   * Try to get actual server information from the flashvars endpoint
   * @param {string} defaultServer - Default server name
   * @returns {Promise<string>} Server name
   * @private
   */
  static async getServerInfo(defaultServer) {
    try {
      const flashvarsData = await HttpClient.fetchFlashvars();
      if (flashvarsData && flashvarsData.smartfoxServer) {
        // Convert internal server format to external format like the game does
        let serverName = flashvarsData.smartfoxServer;
        if (serverName.includes('.internal')) {
          serverName = serverName.replace(/\.(stage|prod)\.animaljam\.internal$/, '-$1.animaljam.com');
          serverName = 'lb-' + serverName;
        }
        return serverName;
      }
    } catch (error) {
      // Ignore errors - we'll use the default
    }
    return defaultServer;
  }
  
  /**
   * Game servers to probe: the public load balancers, plus serverHost when
   * it is another public host.
   * @param {string} serverHost
   * @returns {string[]}
   * @private
   */
  static gameServerHosts(serverHost) {
    const hosts = [...GAME_SERVER_HOSTS];
    if (serverHost && serverHost.endsWith('.animaljam.com') && !hosts.includes(serverHost)) {
      hosts.push(serverHost);
    }
    return hosts;
  }

  /**
   * Opens a TLS connection to a SmartFox game server on 443 (the port the
   * client uses) and sends the client's version check. A live server sends
   * something back; a broken one closes the connection without a byte or
   * never answers.
   * @param {string} host
   * @param {number} [timeoutMs=6000]
   * @returns {Promise<{host: string, ok: boolean, responseTime: number, reason: string}>}
   */
  static probeGameServer(host, timeoutMs = 6000) {
    const tls = require('tls');
    return new Promise((resolve) => {
      const start = performance.now();
      let settled = false;
      let socket = null;
      const finish = (ok, reason) => {
        if (settled) return;
        settled = true;
        if (socket) socket.destroy();
        resolve({ host, ok, responseTime: Math.round(performance.now() - start), reason });
      };
      try {
        socket = tls.connect({ host, port: 443, servername: host, rejectUnauthorized: false });
      } catch (error) {
        finish(false, error.message);
        return;
      }
      socket.setTimeout(timeoutMs);
      socket.on('secureConnect', () => {
        socket.write("<msg t='sys'><body action='verChk' r='0'><ver v='165' /></body></msg>\0");
      });
      socket.on('data', () => finish(true, 'responding'));
      socket.on('timeout', () => finish(false, 'no reply'));
      socket.on('error', (error) => finish(false, error.code || error.message));
      socket.on('close', () => finish(false, 'closed the connection without replying'));
    });
  }

  /**
   * Probes the game servers and downgrades result when any are down.
   * @param {object} result - Status result to update in place
   * @param {string} serverHost
   * @private
   */
  static async applyGameServerStatus(result, serverHost) {
    const probes = await Promise.all(this.gameServerHosts(serverHost).map((host) => this.probeGameServer(host)));
    const down = probes.filter((probe) => !probe.ok);
    result.gameServers = probes;
    if (down.length === 0) return;
    const downText = down.map((probe) => `${probe.host.replace(/^lb-|-classic-prod\.animaljam\.com$/g, '')} (${probe.reason})`).join(', ');
    if (down.length === probes.length) {
      result.isOnline = false;
      result.accessStatus = 'server_error';
      result.details = `Login service is up but no game server is responding: ${downText}`;
    } else {
      result.accessStatus = 'partial';
      result.details = `Some game servers are down: ${downText}. Logins sent to them will fail.`;
    }
  }

  /**
   * Fallback when the login service can't be reached at all: report
   * whether any game server still answers.
   * @param {string} serverHost - The server host to check
   * @returns {Promise<{isOnline: boolean, responseTime: number, timestamp: number, server: string, accessStatus: string, statusCode: number|null, details: string}>} Status result
   * @private
   */
  static async fallbackServerCheck(serverHost) {
    const result = {
      isOnline: true,
      responseTime: 0,
      timestamp: Date.now(),
      server: serverHost,
      accessStatus: 'auth_error',
      statusCode: null,
      details: 'Cannot reach the login service'
    };
    await this.applyGameServerStatus(result, serverHost);
    if (result.isOnline) {
      result.responseTime = Math.min(...result.gameServers.filter((probe) => probe.ok).map((probe) => probe.responseTime));
      if (result.accessStatus !== 'partial') {
        result.details = 'Cannot reach the login service, but the game servers are responding';
      }
      result.accessStatus = 'auth_error';
    }
    return result;
  }
}

module.exports = ServerStatusChecker;
