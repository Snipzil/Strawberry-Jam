const { before, after, test } = require('node:test')
const assert = require('node:assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const asar = require('@electron/asar')
const { ROOT, readJson } = require('./helpers/paths')

const clientDir = path.join(ROOT, 'assets', 'client')
let tmpDir
let archive

// Mirrors `npm run pack`, but writes to a temp dir so the real assets/app-client.asar is untouched.
before(async () => {
  tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'sj-asar-'))
  archive = path.join(tmpDir, 'app-client.asar')
  await asar.createPackageWithOptions(clientDir, archive, { unpack: '*.node' })
})

after(() => fs.rmSync(tmpDir, { recursive: true, force: true }))

test('client packs into an asar', () => {
  assert.ok(fs.statSync(archive).size > 0)
})

test('asar contains package.json and its main entry', () => {
  const files = new Set(asar.listPackage(archive).map((f) => f.replace(/\\/g, '/')))
  const pkg = JSON.parse(asar.extractFile(archive, 'package.json').toString())
  assert.ok(files.has('/package.json'))
  assert.ok(files.has(`/${pkg.main.replace(/^\.\//, '')}`), `main ${pkg.main} not in archive`)
})

test('asar contains every client dependency', () => {
  const files = new Set(asar.listPackage(archive).map((f) => f.replace(/\\/g, '/')))
  const { dependencies } = readJson(path.join(clientDir, 'package.json'))
  const missing = Object.keys(dependencies)
    .filter((d) => d !== 'strawberry-jam')
    .filter((d) => !files.has(`/node_modules/${d}/package.json`))
  assert.deepStrictEqual(missing, [])
})

test('asar does not embed the host repo', () => {
  const leaked = asar.listPackage(archive).find((f) => /[\\/]node_modules[\\/]strawberry-jam([\\/]|$)/.test(f))
  assert.strictEqual(leaked, undefined)
})

test('nothing was unpacked beside the asar', () => {
  assert.ok(!fs.existsSync(`${archive}.unpacked`))
})

test('committed app-client.asar matches the current client sources', () => {
  const committed = path.join(ROOT, 'assets', 'app-client.asar')
  if (!fs.existsSync(committed)) return
  const list = (a) => asar.listPackage(a).map((f) => f.replace(/\\/g, '/')).sort()
  assert.deepStrictEqual(list(committed), list(archive), 'assets/app-client.asar is stale; run npm run pack')
  for (const file of ['package.json', readJson(path.join(clientDir, 'package.json')).main]) {
    assert.ok(asar.extractFile(committed, file).equals(asar.extractFile(archive, file)), `${file} differs; run npm run pack`)
  }
})
