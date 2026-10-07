const { ConnectionMessageTypes, TCP_SERVER_PORTS } = require('../../Constants')
const tls = require('tls')
const DelimiterTransform = require('../transform')
const { Socket } = require('net')
const fs = require('fs')
const os = require('os')
const path = require('path')

/**
 * Messages.
 * @constant
 */
const Message = require('../messages')
const XmlMessage = require('../messages/XmlMessage')
const XtMessage = require('../messages/XtMessage')
const JsonMessage = require('../messages/JsonMessage')

/**
 * Connection message blacklist types
 * @type {Set<string>}
 * @constant
 */
const BLACKLIST_MESSAGES = new Set([
  'apiOK',
  'verChk',
  'rndK',
  'login'
])

/**
 * Maximum message queue size before throttling
 * @type {number}
 * @constant
 */
const MAX_QUEUE_SIZE = 1000 // From jam-master

/**
 * Idle time before TCP keepalive probes start on the AJ socket
 * @type {number}
 * @constant
 */
const KEEPALIVE_DELAY_MS = 30000

/**
 * Client-to-AJ silence after which the last "ka" is replayed. Userspace VPNs
 * answer TCP keepalive probes locally, so only real data keeps their
 * outbound flow to AJ alive (they cut idle flows after ~3-5 min).
 * @type {number}
 * @constant
 */
const HEARTBEAT_IDLE_MS = 60000

/**
 * Connect/disconnect history, so drops can be diagnosed after the fact.
 * @type {string}
 * @constant
 */
const CONNECTION_LOG_PATH = path.join(process.env.APPDATA || os.homedir(), 'strawberry-jam', 'logs', 'connection.log')

module.exports = class Client {
  /**
   * Constructor.
   * @constructor
   */
  constructor (connection, server) {
    /**
     * The server that instantiated this client
     * @type {Server}
     * @private
     */
    this._server = server

    /**
     * The remote connection to Animal Jam
     * @type {TLSSocket | Socket}
     * @private
     */
    this._aj = null // Will be created during connection attempt

    /**
     * Connected indicator
     * @type {boolean}
     * @public
     */
    this.connected = false

    /**
     * The connection that instantiated this client
     * @type {NetifySocket} // Assuming NetifySocket or similar from context
     * @private
     */
    this._connection = connection

    /**
     * Message queue for handling high message volume
     * @type {Object}
     * @private
     */
    this._messageQueue = { // From jam-master
      aj: [],
      connection: [],
      processing: false
    }

    /**
     * Manual disconnect flag to prevent auto-reconnect
     * @type {boolean}
     * @private
     */
    this._manualDisconnect = false // From jam-master

    /**
     * Reconnection attempt counter
     * @type {number}
     * @private
     */
    this._reconnectAttempts = 0 // From jam-master

    /**
     * Flag to prevent spam of disconnect messages
     * @type {boolean}
     * @private
     */
    this._recentlyDisconnected = false

    /**
     * Unique client identifier
     * @type {string}
     * @public
     */
    this.clientId = `client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

    /**
     * Username of the logged-in account
     * @type {string|null}
     * @public
     */
    this.username = null

    /**
     * User ID of the logged-in account
     * @type {string|null}
     * @public
     */
    this.userId = null
  }

  /**
   * Validates and returns the appropriate message type
   * @param {string} message
   * @returns {Message|null}
   * @private
   */
  static validate (message) { // Combined from both, essentially jam-master's version
    try {
      if (!message || typeof message !== 'string') return null

      if (message[0] === '<' && message[message.length - 1] === '>') return new XmlMessage(message)
      if (message[0] === '%' && message[message.length - 1] === '%') return new XtMessage(message)
      if (message[0] === '{' && message[message.length - 1] === '}') return new JsonMessage(message)
      return null
    } catch (error) {
      // console.error('[Client Validate] Error validating message:', error); // Optional: for debugging
      return null
    }
  }

  /**
   * Attempts to create a socket connection
   * @returns {Promise<void>}
   * @public
   */
  async connect () { // Adapted from jam-master
    // Socket will be (re)created in _attemptConnection

    try {
      await this._attemptConnection() // From jam-master

      this._reconnectAttempts = 0 // From jam-master
      this._manualDisconnect = false // From jam-master

      this._setupTransforms()
    } catch (error) {
      if (this._server && this._server.application) {
        this._server.application.consoleMessage({
          message: `Connection error: ${error.message}`,
          type: 'error'
        })
      }

      const shouldAutoReconnect = this._server &&
        this._server.application &&
        this._server.application.settings &&
        typeof this._server.application.settings.get === 'function'
        ? this._server.application.settings.get('autoReconnect') !== false // Default to true if not set
        : true // Default to true if settings path is broken

      if (shouldAutoReconnect && !this._manualDisconnect) {
        await this._handleReconnection() // From jam-master
      }
    }
  }

  /**
   * Attempts the actual socket connection with timeout
   * @returns {Promise<void>}
   * @private
   */
  async _attemptConnection () { // From jam-master
    return new Promise((resolve, reject) => {
      let connectionTimeout = null
      const timeoutDuration = (this._server && this._server.application && this._server.application.settings && this._server.application.settings.get('connectionTimeout')) || 10000;


      const onError = (err) => {
        cleanupListeners()
        clearTimeout(connectionTimeout)
        reject(err)
      }

      const onConnected = () => {
        cleanupListeners()
        clearTimeout(connectionTimeout)
        this.connected = true
        this._connectedAt = Date.now()
        this._lastAjPacketAt = this._connectedAt
        this._closedBy = null
        this._ajSocketError = null
        this._clientIdleKick = false
        this._lastClientPacketAt = this._connectedAt
        this._lastClientKa = null
        this._loginReply = null
        this._recentAjPackets = []
        this._logConnection(`connected to ${smartfoxServer}:${serverPort} (${secureConnection ? 'tls' : 'tcp'})`)
        clearInterval(this._heartbeat)
        this._heartbeat = setInterval(() => this._sendHeartbeat(), 15000)

        // VPNs/NATs drop idle TCP flows (often ~5 min). The game only sends
        // "ka" every 3 min while the player is active, so idle sessions went
        // silent and got cut. TCP keepalive probes keep the flow alive.
        this._aj.setKeepAlive(true, KEEPALIVE_DELAY_MS)
        this._aj.setNoDelay(true)

        if (this._server && this._server.application) { // Check if application exists
            this._server.application.emit('connection:change', true)
        }
        resolve()
      }

      const cleanupListeners = () => {
        this._aj.off('error', onError)
        this._aj.off('connect', onConnected)
      }

      connectionTimeout = setTimeout(() => {
        cleanupListeners()
        this._aj.destroy(); // Ensure socket is destroyed on timeout
        reject(new Error(`Connection timed out after ${timeoutDuration / 1000} seconds`))
      }, timeoutDuration)

      const smartfoxServer = (this._server && this._server.application && this._server.application.settings && this._server.application.settings.get('smartfoxServer')) || 'lb-iss02-classic-prod.animaljam.com';
      
      if (!smartfoxServer || typeof smartfoxServer !== 'string' || !smartfoxServer.includes('animaljam')) {
        cleanupListeners();
        clearTimeout(connectionTimeout);
        reject(new Error('Invalid server address. Unable to connect.'));
        return;
      }
      
      const serverPort = this._server && this._server.actualPort ? this._server.actualPort : TCP_SERVER_PORTS[0]

      const secureConnection = this._server && this._server.application && this._server.application.settings
        ? this._server.application.settings.get('secureConnection') !== false
        : true

      if (secureConnection) {
        // Proper TLS connect with SNI for load balancer routing
        this._aj = tls.connect({
          host: smartfoxServer,
          port: serverPort,
          servername: smartfoxServer,
          rejectUnauthorized: false
        }, onConnected)
        this._aj.once('error', onError)
      } else {
        this._aj = new Socket()
        this._aj.once('error', onError)
        this._aj.once('connect', onConnected)
        this._aj.connect({
          host: smartfoxServer,
          port: serverPort
        })
      }
    })
  }

  /**
   * Handle reconnection attempts with exponential backoff
   * @returns {Promise<void>}
   * @private
   */
  async _handleReconnection () { // From jam-master
    const maxReconnectAttempts = (this._server && this._server.application && this._server.application.settings && this._server.application.settings.get('maxReconnectAttempts')) || 5

    if (this._reconnectAttempts >= maxReconnectAttempts) {
      if (this._server && this._server.application) {
        this._server.application.consoleMessage({
          message: `Failed to reconnect after ${maxReconnectAttempts} attempts.`,
          type: 'error'
        })
      }
      return
    }

    this._reconnectAttempts++

    const baseDelay = 1000
    const maxDelay = 30000
    const jitter = Math.random() * 0.3 // 0-30% jitter

    const delay = Math.min(
      Math.pow(2, this._reconnectAttempts) * baseDelay * (1 + jitter),
      maxDelay
    )
    
    if (this._server && this._server.application) {
      this._server.application.consoleMessage({
        message: `Connection lost, attempting to reconnect in ${Math.round(delay / 1000)}s (${this._reconnectAttempts}/${maxReconnectAttempts})`,
        type: 'warn'
      })
    }

    await new Promise(resolve => setTimeout(resolve, delay))
    return this.connect() // Recursive call to connect
  }


  /**
   * Sets up the necessary transforms for socket connections.
   * @private
   */
  _setupTransforms () { // Adapted from jam-master to use _queueMessage
    const ajTransform = new DelimiterTransform(0x00)
    const connectionTransform = new DelimiterTransform(0x00)

    this._aj
      .pipe(ajTransform)
      .on('data', (message) => {
        message = message.toString() // Already done in DelimiterTransform, but good practice
        this._lastAjPacketAt = Date.now()
        this._trackAjPacket(message)
        try {
          const validatedMessage = this.constructor.validate(message)
          if (validatedMessage) {
            this._queueMessage({ // Use queue from jam-master
              type: ConnectionMessageTypes.aj,
              message: validatedMessage,
              packet: message
            })
          }
        } catch (error) {
          if (this._server && this._server.application) {
            this._server.application.consoleMessage({
              message: `Error processing AJ message: ${error.message}`,
              type: 'error'
            })
          }
        }
      })
      .once('close', () => { // From jam-master
        if (!this._closedBy) this._closedBy = 'server'
        if (this._server && this._server.application && !this._manualDisconnect) {
            this._server.application.emit('connection:change', false)
        }
        this.disconnect() // Calls our updated disconnect
      })
      .on('error', (err) => { // Added error handling for _aj socket
        this._ajSocketError = err.code || err.message
        if (this._server && this._server.application) {
            this._server.application.consoleMessage({
                message: `AJ Socket Error: ${err.message}`,
                type: 'error'
            });
        }
        // this.disconnect(); // Consider if disconnect is always appropriate here
      });


    this._connection
      .pipe(connectionTransform)
      .on('data', (message) => {
        message = message.toString()
        // "ft" is the client's own idle kick (KeepAlive.KICK_INTERVAL, 7 min
        // without Flash mouse/key input), which also shows "gone too long".
        if (/^%xt%[^%]*%ft%/.test(message)) this._clientIdleKick = true
        if (/^%xt%[oa]%ka%/.test(message)) this._lastClientKa = message
        this._lastClientPacketAt = Date.now()
        try {
          const validatedMessage = this.constructor.validate(message)
          if (validatedMessage) {
            this._queueMessage({ // Use queue from jam-master
              type: ConnectionMessageTypes.connection,
              message: validatedMessage,
              packet: message
            })
          }
        } catch (error) {
          if (this._server && this._server.application) {
            this._server.application.consoleMessage({
              message: `Error processing connection message: ${error.message}`,
              type: 'error'
            })
          }
        }
      })
      .once('close', () => {
        if (!this._closedBy) this._closedBy = 'client'
        this.disconnect()
      })
      .on('error', (err) => { // Added error handling for _connection socket
        if (this._server && this._server.application) {
            this._server.application.consoleMessage({
                message: `Local Connection Socket Error: ${err.message}`,
                type: 'error'
            });
        }
        // this.disconnect();
      });

    this._processMessageQueue() // From jam-master
  }

  /**
   * Queues a message for processing
   * @param {Object} messageData - Message data to be processed
   * @private
   */
  _queueMessage (messageData) { // From jam-master
    const queueType = messageData.type === ConnectionMessageTypes.aj ? 'aj' : 'connection'
    const queue = this._messageQueue[queueType]

    if (queue.length > MAX_QUEUE_SIZE) {
      if (this._server && this._server.application) {
        this._server.application.consoleMessage({
          message: `Message queue size for ${queueType} exceeds ${MAX_QUEUE_SIZE} items, possible performance issue`,
          type: 'warn'
        })
      }
      // Optional: Implement strategy for oversized queue (e.g., drop oldest)
    }
    queue.push(messageData)

    if (!this._messageQueue.processing) {
      this._processMessageQueue()
    }
  }

  /**
   * Process messages from the queue
   * @private
   */
  async _processMessageQueue () { // From jam-master
    if (this._messageQueue.processing) return

    this._messageQueue.processing = true

    try {
      // Prioritize connection messages slightly, then AJ messages
      while (this._messageQueue.connection.length > 0) {
        const messageData = this._messageQueue.connection.shift()
        await this._processMessage(messageData)
      }

      while (this._messageQueue.aj.length > 0) {
        const messageData = this._messageQueue.aj.shift()
        await this._processMessage(messageData)
      }
    } catch (error) {
      if (this._server && this._server.application) {
        this._server.application.consoleMessage({
          message: `Error processing message queue: ${error.message}`,
          type: 'error'
        })
      }
    } finally {
      this._messageQueue.processing = false
      // If new messages arrived during processing, re-trigger immediately
      if (this._messageQueue.aj.length > 0 || this._messageQueue.connection.length > 0) {
        setImmediate(() => this._processMessageQueue())
      }
    }
  }

  /**
   * Process a single message from the queue
   * @param {Object} messageData - Message data to process
   * @private
   */
  async _processMessage (messageData) { // From jam-master
    try {
      // Ensure message is parsed (it should be if validate worked)
      if (typeof messageData.message.parse === 'function' && !messageData.message.type) { // Check if already parsed
          messageData.message.parse()
      }
      await this._onMessageReceived(messageData)
    } catch (error) {
      if (this._server && this._server.application) {
        this._server.application.consoleMessage({
          message: `Error processing individual message: ${error.message} for packet: ${messageData.packet}`,
          type: 'error'
        })
      }
    }
  }

  /**
   * Sends a connection message
   * @param message
   * @param {Object} options - Send options
   * @returns {Promise<number>}
   * @public
   */
  sendConnectionMessage (message, options = {}) {
    if (!this._connection || !this._connection.writable || this._connection.destroyed) {
      const state = this._connection
        ? `writable=${this._connection.writable}, destroyed=${this._connection.destroyed}`
        : 'null'
      console.error(`[Client] sendConnectionMessage failed: connection socket ${state}`)
      if (this._server && this._server.application) {
        this._server.application.consoleMessage({
          message: `Cannot send to client: connection socket ${state}`,
          type: 'error'
        })
      }
      return Promise.reject(new Error('Connection socket not writable or destroyed.'))
    }
    return this._sendMessage(this._connection, message, options)
  }

  /**
   * Sends a remote message
   * @param message
   * @param {Object} options - Send options
   * @returns {Promise<number>}
   * @public
   */
  sendRemoteMessage (message, options = {}) { // From jam-master (passes options)
    if (!this._aj || !this._aj.writable || this._aj.destroyed) {
      console.error(`[Client] Attempted to send remote message, but AJ socket is not writable or is destroyed.`);
      if (this._server && this._server.application) {
        this._server.application.consoleMessage({
          message: `Cannot send message: AJ connection not writable.`,
          type: 'error'
        });
      }
      return Promise.reject(new Error('AJ socket not writable or destroyed.'));
    }
    return this._sendMessage(this._aj, message, options);
  }
  
  /**
   * Attempts to send a single message.
   * @param {Socket} socket - The socket to send through
   * @param {string} message - The message to send
   * @returns {Promise<number>} - The length of the message sent
   * @private
   */
  async _attemptSendInternal (socket, message) {
    // message here is expected to be a string, without the null terminator yet.
    const finalMessageString = message + '\x00';
    const messageBuffer = Buffer.from(finalMessageString);

    
    if (!socket.writable || socket.destroyed) {
      console.error(`[Client] _attemptSendInternal: Socket not writable or destroyed. Writable: ${socket.writable}, Destroyed: ${socket.destroyed}`);
      throw new Error('Socket not writable or destroyed in _attemptSendInternal!');
    }

    return new Promise((resolve, reject) => {
      const timeoutDuration = 5000;
      const operationTimeout = setTimeout(() => {
        cleanup();
        reject(new Error('Message send attempt timed out'));
      }, timeoutDuration);

      const onError = (err) => {
        cleanup();
        reject(err);
      };

      const onDrain = () => {
        cleanup();
        resolve(messageBuffer.length); // Length of what was intended to be written
      };

      const onClose = () => {
        cleanup();
        reject(new Error('Socket closed before the message could be sent'));
      };

      const cleanup = () => {
        clearTimeout(operationTimeout);
        socket.off('error', onError);
        socket.off('drain', onDrain);
        socket.off('close', onClose);
      };

      socket.once('error', onError);
      socket.once('drain', onDrain);
      socket.once('close', onClose);

      const writable = socket.write(messageBuffer); // Write the single, combined buffer

      if (writable) {
        cleanup();
        resolve(messageBuffer.length);
      }
    });
  }

  /**
   * Sends a message through the provided socket with retry capability.
   * @param socket
   * @param message
   * @param {Object} options - Send options
   * @param {number} [options.retries=0] - Number of retries
   * @param {number} [options.retryDelay=200] - Delay between retries in ms
   * @returns {Promise<number>}
   * @private
   */
  async _sendMessage (socket, message, { retries = 0, retryDelay = 200 } = {}) { // Kept from previous refactor, now calls _attemptSendInternal
    if (message instanceof Message) message = message.toMessage();

    if (!socket.writable || socket.destroyed) {
      console.error(`[Client] _sendMessage: Initial check failed. Socket not writable or destroyed. Writable: ${socket.writable}, Destroyed: ${socket.destroyed}`);
      throw new Error('Failed to write to socket: Socket initially not writable or destroyed!');
    }

    let attempt = 0;
    let lastError;

    do {
      try {
        if (attempt > 0) {
          await new Promise(resolve => setTimeout(resolve, retryDelay));
           if (this._server && this._server.application) { // Check application exists
            // console.warn(`[Client] Retrying message send (${attempt}/${retries})...`); // Potentially too verbose
          }
        }
        return await this._attemptSendInternal(socket, message);
      } catch (error) {
        lastError = error;
        attempt++;
        if (this._server && this._server.application) {
           console.warn(`[Client] _sendMessage: Attempt ${attempt} failed. Error: ${error.message}`);
        }
      }
    } while (attempt <= retries);
    
    const errorMessage = `Message sending failed after ${retries + 1} attempts: ${lastError?.message || 'Unknown error'}`;
    if (this._server && this._server.application) {
      this._server.application.consoleMessage({
        message: errorMessage,
        type: 'error'
      });
    }
    console.error(`[Client] _sendMessage: ${errorMessage}`);
    throw lastError || new Error('Failed to send message after multiple retries.');
  }


  /**
   * Handles received message.
   * @param {Object} messageData - Message data to process
   * @param {string} messageData.type - Type of the message (aj or connection)
   * @param {Message} messageData.message - The message object
   * @param {string} messageData.packet - The raw message packet
   * @private
   */
  async _onMessageReceived ({ type, message, packet }) {
    if (!this.connected) return

    if (this._server && this._server.application && this._server.application.dispatch) {
        await this._server.application.dispatch.all({ client: this, type, message })
    }


    if (type === ConnectionMessageTypes.connection && typeof packet === 'string' && packet.trim().startsWith('<policy-file-request')) {
      const allPorts = TCP_SERVER_PORTS.join(',')
      const crossDomainMessage = `<?xml version="1.0"?>\n        <!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd">\n        <cross-domain-policy>\n        <allow-access-from domain="*" to-ports="80,${allPorts}"/>\n        </cross-domain-policy>`

      await this.sendConnectionMessage(crossDomainMessage)
      return
    }

    if (type === ConnectionMessageTypes.aj && packet.includes('cross-domain-policy')) {
      const allPorts = TCP_SERVER_PORTS.join(',')
      const crossDomainMessage = `<?xml version="1.0"?>
        <!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd">
        <cross-domain-policy>
        <allow-access-from domain="*" to-ports="80,${allPorts}"/>
        </cross-domain-policy>`

      await this.sendConnectionMessage(crossDomainMessage)
      return
    }

    // Handle blacklisted messages
    if (type === ConnectionMessageTypes.connection && BLACKLIST_MESSAGES.has(message.type)) {
      await this.sendRemoteMessage(packet) // Send the raw packet string
      return
    }

    if (message.send) { // message is an instance of Message class here
      if (type === ConnectionMessageTypes.connection) {
        await this.sendRemoteMessage(message) // sendRemoteMessage will call .toMessage() if it's a Message instance
      } else {
        await this.sendConnectionMessage(message) // same here
      }
    }
  }

  /**
   * Disconnects the session from the remote host and server.
   * @param {boolean} manual - Whether this is a manual disconnect
   * @returns {Promise<void>}
   * @public
   */
  async disconnect (manual = false) { // From jam-master
    this._manualDisconnect = manual;
    clearInterval(this._heartbeat);
    if (this.connected) {
      this._logConnection(`disconnected${manual ? ' (manual)' : ''}: ${this._describeDisconnect()}`);
    }

    if (this._connection && !this._connection.destroyed) {
      this._connection.destroy();
    }

    if (this._aj && !this._aj.destroyed) {
      this._aj.destroy();
    }
    
    if (this._server && this._server.application && this._server.application.dispatch && this._server.application.dispatch.intervals) {
        this._server.application.dispatch.intervals.forEach((intervalId) => {
            if (this._server.application.dispatch.clearInterval) { // Check if function exists
                this._server.application.dispatch.clearInterval(intervalId);
            }
        });
        this._server.application.dispatch.intervals.clear();
    }

    const wasConnected = this.connected;
    
    if (this.connected) {
      this.connected = false;
      if (this._server && this._server.application && !manual) {
        this._server.application.emit('connection:change', false);
      }
    }
    
    if (this._server && this._server.application && !manual && wasConnected) {
      if (!this._recentlyDisconnected) {
        const isGameClosing = this._server.application._isGameRunning === false;
        const wasJustLaunched = (typeof this._wasGameJustLaunched === 'function') ? this._wasGameJustLaunched() : false;
        
        if (!isGameClosing && !wasJustLaunched) {
          this._recentlyDisconnected = true;
          this._server.application.consoleMessage({
              message: `Connection to Animal Jam servers closed. ${this._describeDisconnect()}`,
              type: 'notify'
          });
          
          setTimeout(() => {
            this._recentlyDisconnected = false;
          }, 10000);
        } else {
          this._recentlyDisconnected = true;
          setTimeout(() => {
            this._recentlyDisconnected = false;
          }, 2000);
        }
      }
    }
    
    // Clear queues
    this._messageQueue.aj = [];
    this._messageQueue.connection = [];

    if (this._server && this._server.clients) { // Check server and clients set exist
        this._server.clients.delete(this);
    }
  }
  /**
   * Replays the game's own last "ka" when the client has gone quiet, so the
   * AJ flow never idles long enough for a VPN to drop it.
   * @private
   */
  _sendHeartbeat () {
    if (!this.connected || !this._lastClientKa) return
    if (Date.now() - this._lastClientPacketAt < HEARTBEAT_IDLE_MS) return
    this._lastClientPacketAt = Date.now()
    this.sendRemoteMessage(this._lastClientKa).catch(() => {})
  }

  /**
   * Keeps the names of the last few server packets, and AJ's verdict on the
   * world login, so a rejected login can be explained. Payloads are not kept.
   * @param {string} message
   * @private
   */
  _trackAjPacket (message) {
    let name = message.slice(0, 24)
    if (message[0] === '{') {
      try {
        const o = JSON.parse(message).b.o
        name = `json:${o._cmd}`
        if (o._cmd === 'login') {
          this._loginReply = `status=${o.status} statusId=${o.statusId}${o.message ? ` message="${String(o.message).slice(0, 200)}"` : ''}`
        }
      } catch (err) {}
    } else if (message.startsWith('%xt%')) {
      name = `xt:${message.split('%')[2]}`
    } else if (message[0] === '<') {
      const action = /action='([^']*)'/.exec(message)
      name = `xml:${action ? action[1] : '?'}`
    }
    this._recentAjPackets.push(name)
    if (this._recentAjPackets.length > 8) this._recentAjPackets.shift()
  }

  /**
   * @param {string} line
   * @private
   */
  _logConnection (line) {
    try {
      fs.mkdirSync(path.dirname(CONNECTION_LOG_PATH), { recursive: true })
      fs.appendFileSync(CONNECTION_LOG_PATH, `[${new Date().toISOString()}] ${line}
`)
    } catch (err) {}
  }

  /**
   * Explains who dropped the session, since the game shows "you were gone
   * too long" for every kind of disconnect.
   * @returns {string}
   * @private
   */
  _describeDisconnect () {
    const now = Date.now()
    const mins = this._connectedAt ? Math.round((now - this._connectedAt) / 60000) : 0
    const quietSecs = this._lastAjPacketAt ? Math.round((now - this._lastAjPacketAt) / 1000) : 0
    let reason
    if (this._clientIdleKick) {
      reason = 'Idle kick: no mouse/keyboard input in the game for 7 min (turn on Anti-AFK to prevent this).'
    } else if (this._ajSocketError) {
      reason = `Network error (${this._ajSocketError}), usually the VPN or internet dropping.`
    } else if (this._closedBy === 'server' && mins < 1) {
      // Seen with VPN/datacenter IPs: auth passes, then the game server
      // drops the socket mid world-login ("Login world error").
      reason = 'Animal Jam rejected the login. If you are on a VPN, its IP is likely blocked; try another server or turn it off.'
    } else if (this._closedBy === 'server') {
      reason = 'Animal Jam closed the connection.'
    } else if (this._closedBy === 'client') {
      reason = 'The game client closed the connection.'
    } else {
      reason = 'Reason unknown.'
    }
    const login = this._loginReply ? `, login reply ${this._loginReply}` : ''
    const recent = this._recentAjPackets && this._recentAjPackets.length ? `, last packets ${this._recentAjPackets.join(' ')}` : ''
    return `${reason} (session ${mins}m, last server packet ${quietSecs}s ago${login}${recent})`
  }

   /**
   * Checks if Animal Jam was just successfully launched.
   * @returns {boolean} True if the game was launched within the last 5 seconds
   * @private
   */
  _wasGameJustLaunched() { // Copied from current project as it's useful
    try {
      const messagesContainer = document.getElementById('messages');
      if (!messagesContainer) return false;
      
      const messages = messagesContainer.getElementsByClassName('message-animate-in');
      if (!messages || messages.length === 0) return false;
      
      const messageCount = Math.min(messages.length, 10); 
      for (let i = messages.length - 1; i >= messages.length - messageCount; i--) {
        const messageElement = messages[i];
        if (!messageElement) continue;
        
        const successText = messageElement.textContent || '';
        if (successText.includes('Successfully launched Strawberry Jam Classic')) {
          const timestampElement = messageElement.querySelector('.text-xs.text-gray-500');
          if (!timestampElement) return true; 
          
          const timestampText = timestampElement.textContent || '';
          const currentTime = new Date();
          const messageParts = timestampText.split(':');
          
          if (messageParts.length === 3) {
            const messageTime = new Date();
            messageTime.setHours(parseInt(messageParts[0], 10));
            messageTime.setMinutes(parseInt(messageParts[1], 10));
            messageTime.setSeconds(parseInt(messageParts[2], 10));
            
            const timeDiff = currentTime - messageTime;
            return timeDiff < 5000; 
          }
          return true; 
        }
      }
      return false; 
    } catch (e) {
      return false;
    }
  }
}
