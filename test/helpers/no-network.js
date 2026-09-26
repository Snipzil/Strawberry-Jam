// Preloaded into every test process: any non-loopback connection or DNS lookup throws.
const net = require('net')
const dns = require('dns')

const LOOPBACK = new Set(['localhost', '127.0.0.1', '::1', undefined])

class OfflineViolation extends Error {
  constructor(target) {
    super(`Offline test attempted network access to ${target}`)
    this.code = 'EOFFLINE'
  }
}

// net.connect passes a pre-normalized [options, cb] array; direct callers pass (options) or (port, host).
const connectTarget = (args) => {
  const first = Array.isArray(args[0]) ? args[0][0] : args[0]
  if (first && typeof first === 'object') return first
  if (typeof first === 'string' && isNaN(Number(first))) return { path: first }
  return { port: first, host: typeof args[1] === 'string' ? args[1] : undefined }
}

const originalConnect = net.Socket.prototype.connect
net.Socket.prototype.connect = function (...args) {
  const { path, host, port } = connectTarget(args)
  if (!path && !LOOPBACK.has(host)) throw new OfflineViolation(`${host}:${port}`)
  return originalConnect.apply(this, args)
}

const blockLookup = (original) => function (hostname, ...rest) {
  if (LOOPBACK.has(hostname)) return original.call(this, hostname, ...rest)
  throw new OfflineViolation(hostname)
}
dns.lookup = blockLookup(dns.lookup)
dns.promises.lookup = blockLookup(dns.promises.lookup)

module.exports = { OfflineViolation }
