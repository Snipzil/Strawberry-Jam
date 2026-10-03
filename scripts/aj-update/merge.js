const fs = require('fs')
const path = require('path')
const { spawnSync } = require('child_process')

// FFDec names scripts that aren't a single class (frame/document scripts)
// script_<index>.as. The index shifts between builds, so they can't be
// matched by name.
const UNNAMED_SCRIPT = /(^|\/)script_\d+\.as$/

const CONFLICT_MARKER = /^(<{7}|={7}|>{7})( |$)/m

/** Recursively lists `.as` files under `root`, keyed by `/`-separated relative path. */
function listScripts (root) {
  const out = new Map()
  if (!fs.existsSync(root)) return out
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const abs = path.join(dir, entry.name)
      if (entry.isDirectory()) walk(abs)
      else if (entry.name.endsWith('.as')) out.set(path.relative(root, abs).split(path.sep).join('/'), abs)
    }
  }
  walk(root)
  return out
}

/** `gui/GuiManager.as` -> `gui.GuiManager` */
function classNameFromPath (rel) {
  return rel.replace(/\.as$/, '').split('/').join('.')
}

function normalize (text) {
  return text.replace(/\r\n/g, '\n')
}

function readNormalized (file) {
  return normalize(fs.readFileSync(file, 'utf8'))
}

function hasConflictMarkers (text) {
  return CONFLICT_MARKER.test(text)
}

/**
 * Compares two script exports and returns what changed from `baseDir` to
 * `theirsDir` (both FFDec `-export script` output folders).
 */
function diffExports (baseDir, theirsDir) {
  const base = listScripts(baseDir)
  const theirs = listScripts(theirsDir)
  const changed = []
  const added = []
  const removed = []
  const unnamedBase = new Set()
  const unnamedTheirs = []

  for (const [rel, file] of base) {
    if (UNNAMED_SCRIPT.test(rel)) { unnamedBase.add(readNormalized(file)); continue }
    if (!theirs.has(rel)) removed.push(rel)
    else if (readNormalized(file) !== readNormalized(theirs.get(rel))) changed.push(rel)
  }
  for (const [rel, file] of theirs) {
    if (UNNAMED_SCRIPT.test(rel)) { unnamedTheirs.push({ rel, text: readNormalized(file) }); continue }
    if (!base.has(rel)) added.push(rel)
  }
  const unnamedChanged = unnamedTheirs.filter(s => !unnamedBase.has(s.text)).map(s => s.rel)

  return { changed: changed.sort(), added: added.sort(), removed: removed.sort(), unnamedChanged: unnamedChanged.sort() }
}

/**
 * Three-way merges one class with `git merge-file`.
 * Returns { text, conflicts } with `\n` line endings; `conflicts` is the
 * number of conflicting hunks (0 = clean).
 */
function mergeText ({ ours, base, theirs, labels = ['strawberry-jam', 'base', 'aj'], tmpDir }) {
  fs.mkdirSync(tmpDir, { recursive: true })
  const files = ['ours', 'base', 'theirs'].map(n => path.join(tmpDir, `${n}.as`))
  fs.writeFileSync(files[0], normalize(ours))
  fs.writeFileSync(files[1], normalize(base))
  fs.writeFileSync(files[2], normalize(theirs))
  const res = spawnSync('git', [
    'merge-file', '-p', '--diff3',
    '-L', labels[0], '-L', labels[1], '-L', labels[2],
    ...files
  ], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })
  if (res.error) throw new Error(`git merge-file failed to run: ${res.error.message}`)
  // Exit status is the conflict count (capped at 127); anything above is an error.
  if (res.status === null || res.status > 127) {
    throw new Error(`git merge-file failed: ${res.stderr || `status ${res.status}`}`)
  }
  return { text: res.stdout, conflicts: res.status }
}

function containsBlock (haystack, needle) {
  if (needle.length === 0) return true
  for (let i = 0; i + needle.length <= haystack.length; i++) {
    let j = 0
    while (j < needle.length && haystack[i + j] === needle[j]) j++
    if (j === needle.length) return true
  }
  return false
}

/**
 * Settles the conflict hunks (diff3 style) where both sides only added lines
 * and one side's addition contains the other's, e.g. we ported pets 117-119 by
 * hand and AJ's update adds 117-123 in the same spot. Keeping the larger side
 * loses nothing. Every other hunk is left for a human.
 * Returns { text, remaining } where remaining is the number of hunks left.
 */
function autoResolveAdditions (text) {
  const lines = text.split('\n')
  const out = []
  let remaining = 0
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith('<<<<<<< ')) { out.push(lines[i]); continue }
    const hunk = { ours: [], base: [], theirs: [] }
    let part = 'ours'
    let j = i + 1
    for (; j < lines.length; j++) {
      const l = lines[j]
      if (part === 'ours' && l.startsWith('||||||| ')) part = 'base'
      else if (part !== 'theirs' && l === '=======') part = 'theirs'
      else if (part === 'theirs' && l.startsWith('>>>>>>> ')) break
      else hunk[part].push(l)
    }
    if (j >= lines.length) { out.push(...lines.slice(i)); remaining++; break }
    const baseEmpty = hunk.base.every(l => l.trim() === '')
    if (baseEmpty && containsBlock(hunk.theirs, hunk.ours)) out.push(...hunk.theirs)
    else if (baseEmpty && containsBlock(hunk.ours, hunk.theirs)) out.push(...hunk.ours)
    else { out.push(...lines.slice(i, j + 1)); remaining++ }
    i = j
  }
  return { text: out.join('\n'), remaining }
}

/**
 * Decides what one class AJ changed (or added) should become in our client.
 *
 *   base   - AJ's previous version ('' for a class AJ just added)
 *   theirs - AJ's new version
 *   ours   - our current version (null if our client doesn't have it)
 *   resolvedText - a conflict file from an earlier run, if one exists
 *
 * Returns { action, text } where action is one of:
 *   'theirs'    we never modified it: take AJ's version as is
 *   'unchanged' ours already matches (already ported): nothing to compile
 *   'merged'    clean three-way merge of our mods onto AJ's version
 *   'resolved'  a human finished an earlier conflict file
 *   'conflict'  needs a human; text has diff3 conflict markers
 */
function resolveClass ({ base, theirs, ours, resolvedText = null, labels, tmpDir }) {
  if (resolvedText !== null) {
    return hasConflictMarkers(resolvedText)
      ? { action: 'conflict', text: normalize(resolvedText) }
      : { action: 'resolved', text: normalize(resolvedText) }
  }
  base = normalize(base)
  theirs = normalize(theirs)
  if (ours === null) return { action: 'theirs', text: theirs }
  ours = normalize(ours)
  if (ours === theirs) return { action: 'unchanged', text: ours }
  if (ours === base) return { action: 'theirs', text: theirs }
  const merged = mergeText({ ours, base, theirs, labels, tmpDir })
  let text = merged.text
  if (merged.conflicts > 0) {
    const settled = autoResolveAdditions(text)
    if (settled.remaining > 0) return { action: 'conflict', text: settled.text }
    text = settled.text
  }
  if (text === ours) return { action: 'unchanged', text: ours }
  return { action: 'merged', text }
}

module.exports = {
  UNNAMED_SCRIPT,
  resolveClass,
  autoResolveAdditions,
  listScripts,
  classNameFromPath,
  normalize,
  hasConflictMarkers,
  diffExports,
  mergeText
}
