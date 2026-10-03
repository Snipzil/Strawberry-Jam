const { describe, test, before, after } = require('node:test')
const assert = require('node:assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { ROOT, readJson } = require('./helpers/paths')
const {
  resolveClass,
  autoResolveAdditions,
  diffExports,
  classNameFromPath,
  hasConflictMarkers
} = require('../scripts/aj-update/merge')

let tmp
before(() => { tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'aj-update-test-')) })
after(() => fs.rmSync(tmp, { recursive: true, force: true }))

const lines = (...l) => l.join('\n') + '\n'
const resolve = (args) => resolveClass({ labels: ['ours', 'base', 'theirs'], tmpDir: path.join(tmp, 'merge'), ...args })

describe('resolveClass', () => {
  const base = lines('a', 'b', 'c', 'd', 'e', 'f', 'g')

  test('takes AJ\'s version when we never modified the class', () => {
    const theirs = lines('a', 'b', 'c', 'NEW', 'd', 'e', 'f', 'g')
    assert.deepStrictEqual(resolve({ base, theirs, ours: base }), { action: 'theirs', text: theirs })
  })

  test('takes AJ\'s version for a class we don\'t have', () => {
    assert.strictEqual(resolve({ base: '', theirs: 'x\n', ours: null }).action, 'theirs')
  })

  test('merges our edits and AJ\'s edits in different places', () => {
    const ours = lines('a', 'OURS', 'c', 'd', 'e', 'f', 'g')
    const theirs = lines('a', 'b', 'c', 'd', 'e', 'THEIRS', 'g')
    assert.deepStrictEqual(resolve({ base, theirs, ours }), {
      action: 'merged',
      text: lines('a', 'OURS', 'c', 'd', 'e', 'THEIRS', 'g')
    })
  })

  test('ignores CRLF vs LF differences', () => {
    const ours = lines('a', 'OURS', 'c', 'd', 'e', 'f', 'g').replace(/\n/g, '\r\n')
    assert.strictEqual(resolve({ base, theirs: base.replace(/\n/g, '\r\n'), ours }).action, 'unchanged')
  })

  test('reports already-ported changes as unchanged', () => {
    const ours = lines('a', 'OURS', 'c', 'd', 'e', 'f', 'g')
    assert.strictEqual(resolve({ base, theirs: ours, ours }).action, 'unchanged')
  })

  test('flags overlapping edits as a conflict with diff3 markers', () => {
    const res = resolve({ base, ours: lines('a', 'b', 'c', 'OURS', 'e', 'f', 'g'), theirs: lines('a', 'b', 'c', 'THEIRS', 'e', 'f', 'g') })
    assert.strictEqual(res.action, 'conflict')
    assert.ok(hasConflictMarkers(res.text))
    assert.match(res.text, /\|{7} base\nd\n/)
  })

  test('auto-resolves an addition AJ extended (we ported part of it by hand)', () => {
    const before = ['switch(x)', '{', 'case 1:', 'return 1;']
    const after = ['}', 'end']
    const res = resolve({
      base: lines(...before, ...after),
      ours: lines(...before, 'case 117:', 'return 117;', ...after),
      theirs: lines(...before, 'case 117:', 'return 117;', 'case 120:', 'return 120;', ...after)
    })
    assert.deepStrictEqual(res, {
      action: 'merged',
      text: lines(...before, 'case 117:', 'return 117;', 'case 120:', 'return 120;', ...after)
    })
  })

  test('uses a finished conflict file as is, and keeps an unfinished one a conflict', () => {
    assert.deepStrictEqual(resolve({ base, theirs: base, ours: base, resolvedText: 'done\r\n' }), { action: 'resolved', text: 'done\n' })
    const pending = lines('<<<<<<< ours', 'x', '=======', 'y', '>>>>>>> theirs')
    assert.strictEqual(resolve({ base, theirs: base, ours: base, resolvedText: pending }).action, 'conflict')
  })
})

describe('autoResolveAdditions', () => {
  test('keeps hunks where the sides really disagree', () => {
    const text = lines('<<<<<<< ours', 'x', '||||||| base', 'o', '=======', 'x', 'y', '>>>>>>> theirs')
    assert.deepStrictEqual(autoResolveAdditions(text), { text, remaining: 1 })
  })

  test('keeps add/add hunks where neither side contains the other', () => {
    const text = lines('<<<<<<< ours', 'x', '||||||| base', '=======', 'y', '>>>>>>> theirs')
    assert.strictEqual(autoResolveAdditions(text).remaining, 1)
  })

  test('keeps our side when it contains AJ\'s', () => {
    const text = lines('k', '<<<<<<< ours', 'x', 'y', '||||||| base', '=======', 'y', '>>>>>>> theirs', 'k')
    assert.deepStrictEqual(autoResolveAdditions(text), { text: lines('k', 'x', 'y', 'k'), remaining: 0 })
  })
})

describe('diffExports', () => {
  test('finds changed, added and removed classes and changed unnamed scripts', () => {
    const write = (root, rel, text) => {
      const file = path.join(root, ...rel.split('/'))
      fs.mkdirSync(path.dirname(file), { recursive: true })
      fs.writeFileSync(file, text)
    }
    const base = path.join(tmp, 'export-base')
    const theirs = path.join(tmp, 'export-theirs')
    write(base, 'gui/Same.as', 'same\r\n')
    write(theirs, 'gui/Same.as', 'same\n')
    write(base, 'pet/PetBase.as', 'old')
    write(theirs, 'pet/PetBase.as', 'new')
    write(base, 'Gone.as', 'x')
    write(theirs, 'avatar/Added.as', 'x')
    write(base, 'script_10.as', 'frame')
    write(theirs, 'script_11.as', 'frame')
    write(theirs, 'script_12.as', 'new frame')

    assert.deepStrictEqual(diffExports(base, theirs), {
      changed: ['pet/PetBase.as'],
      added: ['avatar/Added.as'],
      removed: ['Gone.as'],
      unnamedChanged: ['script_12.as']
    })
  })

  test('maps export paths to class names', () => {
    assert.strictEqual(classNameFromPath('it/gotoandplay/smartfoxserver/SmartFoxClient.as'), 'it.gotoandplay.smartfoxserver.SmartFoxClient')
    assert.strictEqual(classNameFromPath('MainFrame.as'), 'MainFrame')
  })
})

describe('state.json', () => {
  const state = readJson(path.join(ROOT, 'scripts', 'aj-update', 'state.json'))

  test('every client records a deploy with a known vanilla hash', () => {
    for (const name of ['modded', 'unmodded']) {
      const deploy = state.targets[name] && state.targets[name].deploy
      assert.match(String(deploy), /^\d+$/, `${name} deploy`)
      assert.match(state.vanilla[deploy] || '', /^[0-9a-f]{64}$/, `vanilla hash for deploy ${deploy}`)
    }
  })
})
