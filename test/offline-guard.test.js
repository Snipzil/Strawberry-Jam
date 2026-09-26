const { test } = require('node:test')
const assert = require('node:assert')
const net = require('net')
const dns = require('dns')

test('network guard is preloaded', () => {
  assert.throws(() => net.connect(443, 'github.com'), { code: 'EOFFLINE' })
  assert.throws(() => dns.lookup('github.com', () => {}), { code: 'EOFFLINE' })
})

test('fetch to a remote host fails instead of reaching the network', async () => {
  await assert.rejects(fetch('https://api.github.com/'))
})

test('loopback connections are still allowed', async () => {
  const server = net.createServer((s) => s.end())
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
  const { port } = server.address()
  await new Promise((resolve, reject) => {
    const socket = net.connect(port, '127.0.0.1', () => { socket.end(); resolve() })
    socket.on('error', reject)
  })
  server.close()
})
