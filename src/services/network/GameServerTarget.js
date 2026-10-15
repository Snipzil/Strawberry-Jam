const fs = require('fs')
const os = require('os')
const path = require('path')
const http = require('http')
const https = require('https')

/**
 * Which game server the proxy relays to: Animal Jam (no file, the default)
 * or a Burrow private server (https://github.com/burrow-dev/burrow-server).
 *
 * The choice lives in one file so the processes that care can share it: the
 * launcher's Burrow mode switch writes it; the proxy (here), the API's asset
 * proxy (src/api) and the AJ Classic client's login screen (assets/client)
 * read it. Shape:
 *   { "server": "burrow", "url": "https://play.burrow.moe", "client": "strawberry" }
 * `client` is the game client played with: "strawberry" (Strawberry Jam's
 * modded SWF, the default) or "burrow" (the server's own).
 *
 * @module GameServerTarget
 */
const TARGET_PATH = path.join(process.env.APPDATA || os.homedir(), 'strawberry-jam', 'game-server.json')

const LOOPBACK_HOSTS = ['127.0.0.1', 'localhost', '[::1]']
const DEFAULT_BURROW_URL = 'https://play.burrow.moe'
const CLIENTS = ['strawberry', 'burrow']
const FLASHVARS_TTL_MS = 60000
const FLASHVARS_TIMEOUT_MS = 10000

let cached = null // { url, at, upstream }

/**
 * The whole saved choice, normalized: { server: 'burrow', url, client } or
 * { server: 'animaljam', url, client } (url and client kept for switching back).
 * @returns {{server: string, url: string, client: string}}
 */
function read () {
  let target = {}
  try {
    target = JSON.parse(fs.readFileSync(TARGET_PATH, 'utf8')) || {}
  } catch (_) {}
  let url = DEFAULT_BURROW_URL
  try {
    const parsed = new URL(target.url)
    if (['http:', 'https:'].includes(parsed.protocol)) url = parsed.origin
  } catch (_) {}
  return {
    server: target.server === 'burrow' ? 'burrow' : 'animaljam',
    url,
    client: CLIENTS.includes(target.client) ? target.client : 'strawberry'
  }
}

/**
 * Saves changes to the choice (any of server, url, client).
 * @returns {{server: string, url: string, client: string}} the saved choice
 */
function write (changes) {
  const next = Object.assign(read(), changes)
  fs.mkdirSync(path.dirname(TARGET_PATH), { recursive: true })
  fs.writeFileSync(TARGET_PATH, JSON.stringify(next, null, 2))
  cached = null
  return read()
}

/**
 * The Burrow server's base URL ("https://play.burrow.moe"), or null when the
 * game goes to Animal Jam.
 * @returns {string|null}
 */
function burrowUrl () {
  const target = read()
  return target.server === 'burrow' ? target.url : null
}

function getJson (url) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https:') ? https : http
    const req = lib.get(url, { timeout: FLASHVARS_TIMEOUT_MS }, (res) => {
      let data = ''
      res.setEncoding('utf8')
      res.on('data', chunk => { data += chunk })
      res.on('end', () => {
        if (res.statusCode !== 200) return reject(new Error(`${url} answered ${res.statusCode}`))
        try { resolve(JSON.parse(data)) } catch (_) { reject(new Error(`${url} did not answer with JSON`)) }
      })
    })
    req.on('timeout', () => req.destroy(new Error(`${url} timed out`)))
    req.on('error', reject)
  })
}

/**
 * Where the proxy should connect for the selected Burrow server, read from its
 * /flashvars like Burrow's own client does (its app/relay.js): the game host
 * and port the server names, over TLS when the server's address is https.
 * @returns {Promise<{host: string, port: number, secure: boolean, server: string}|null>}
 *   null when the game goes to Animal Jam.
 */
async function resolveUpstream () {
  const server = burrowUrl()
  if (!server) return null
  if (cached && cached.url === server && Date.now() - cached.at < FLASHVARS_TTL_MS) return cached.upstream

  const flashVars = await getJson(`${server}/flashvars`)
  const port = Number(flashVars.smartfoxPort)
  if (!flashVars.clientURL || !Number.isInteger(port) || port <= 0 || port > 65535) {
    throw new Error(`${server} is not a Burrow server`)
  }
  const { hostname, protocol } = new URL(server)
  // a server on this computer is never sent elsewhere, whatever it names
  const host = LOOPBACK_HOSTS.includes(hostname) || typeof flashVars.smartfoxServer !== 'string' || !flashVars.smartfoxServer
    ? hostname
    : flashVars.smartfoxServer
  const upstream = { host, port, secure: protocol === 'https:', server }
  cached = { url: server, at: Date.now(), upstream }
  return upstream
}

module.exports = { TARGET_PATH, DEFAULT_BURROW_URL, read, write, burrowUrl, resolveUpstream, getJson }
