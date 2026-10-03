#!/usr/bin/env node
// Ports an Animal Jam client update (a new ajclient.swf "deploy") into our
// clients automatically. See scripts/aj-update/README.md.
//
//   npm run aj:check          is there a new AJ deploy?
//   npm run aj:update         port it (re-run after resolving any conflicts)

const fs = require('fs')
const os = require('os')
const path = require('path')
const crypto = require('crypto')
const { spawnSync } = require('child_process')
const { diffExports, classNameFromPath, resolveClass, listScripts, normalize } = require('./merge')

const ROOT = path.join(__dirname, '..', '..')
const TOOL_DIR = path.join(__dirname, 'tool')
const STATE_FILE = path.join(__dirname, 'state.json')
const WORK_ROOT = path.join(__dirname, 'work')
const FLASH_DIR = path.join(ROOT, 'assets', 'flash')

const FLASHVARS_URL = 'https://www.animaljam.com/flashvars'
const CONTENT_URL = 'https://ajcontent.akamaized.net'
const FFDEC_HOME = process.env.FFDEC_HOME || 'C:\\Program Files (x86)\\FFDec'
// Tags whose bytes change on every build without mattering.
const IGNORED_TAGS = /^(Metadata)@/

// The clients we keep in sync with AJ. Each records in state.json the
// vanilla deploy it was last synced to; that deploy is the merge base.
//
// mode 'patch':   keep our SWF and compile in every class AJ changed
//                 (three-way merged with our edits). Classes AJ didn't touch
//                 keep their bytecode, so nothing else gets recompiled.
// mode 'overlay': start from AJ's fresh SWF and compile in only `classes`
//                 (three-way merged). For clients that are vanilla plus a
//                 small hook.
const TARGETS = {
  modded: {
    mode: 'patch',
    swf: path.join(FLASH_DIR, 'ajclient.swf'),
    // Hand-maintained whole-class sources. They are "ours" for their classes
    // and get the merged result written back, so a later PatchTool rebuild
    // doesn't undo AJ's changes.
    sourceDirs: [path.join(ROOT, 'scripts', 'patches', 'src')]
  },
  unmodded: {
    mode: 'overlay',
    swf: path.join(FLASH_DIR, 'options', 'unmodded-ajclient.swf'),
    // Points the client at the local proxy (127.0.0.1, no secure socket).
    classes: ['it.gotoandplay.smartfoxserver.SmartFoxClient'],
    sourceDirs: []
  }
}

function printHelp () {
  console.log(`Usage: node scripts/aj-update/aj-update.js [options]

  --check            only report whether AJ has a newer deploy (exit 1 if so)
  --target <name>    only update this client: ${Object.keys(TARGETS).join(', ')} (default: all)
  --deploy <n>       target this deploy instead of the live one
  --force            rebuild even if state.json says the client is up to date
  --no-install       build into the work dir only; don't touch assets, sources or state
  --base-swf <f>     vanilla client to use as the merge base (one --target only)
  --ours-swf <f>     client to update instead of the target's own (one --target only)
  --ignore-sources   use the decompiled client instead of scripts/patches/src

Env: FFDEC_HOME (default ${FFDEC_HOME}), JAVA_HOME
Work files (downloads, exports, conflicts, reports): scripts/aj-update/work/`)
}

function parseArgs (argv) {
  const opts = { check: false, force: false, install: true, useSources: true, targets: Object.keys(TARGETS) }
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    const value = () => {
      if (i + 1 >= argv.length) fail(`${a} needs a value`)
      return argv[++i]
    }
    if (a === '--check') opts.check = true
    else if (a === '--force') opts.force = true
    else if (a === '--no-install') opts.install = false
    else if (a === '--ignore-sources') opts.useSources = false
    else if (a === '--deploy') opts.deploy = value()
    else if (a === '--target') {
      const t = value()
      if (!TARGETS[t]) fail(`unknown target ${t}`)
      opts.targets = [t]
    } else if (a === '--base-swf') opts.baseSwf = path.resolve(value())
    else if (a === '--ours-swf') opts.oursSwf = path.resolve(value())
    else if (a === '-h' || a === '--help') { printHelp(); process.exit(0) } else fail(`unknown option ${a} (see --help)`)
  }
  if ((opts.baseSwf || opts.oursSwf) && opts.targets.length !== 1) fail('--base-swf/--ours-swf need a single --target')
  return opts
}

// Thrown rather than process.exit(): exiting right after fetch() trips a libuv
// assertion on Windows.
class UpdateError extends Error {}

function fail (msg) {
  throw new UpdateError(msg)
}

function log (msg) {
  console.log(`[aj-update] ${msg}`)
}

function rel (file) {
  return path.relative(ROOT, file)
}

function sha256 (file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')
}

function readState () {
  if (!fs.existsSync(STATE_FILE)) fail(`missing ${rel(STATE_FILE)}`)
  return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'))
}

function writeState (state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2) + '\n')
}

async function fetchLiveDeploy () {
  const res = await fetch(FLASHVARS_URL)
  if (!res.ok) fail(`flashvars request failed: HTTP ${res.status}`)
  const data = await res.json()
  if (!data.deploy_version) fail('flashvars has no deploy_version')
  return String(data.deploy_version)
}

/** Vanilla ajclient.swf for a deploy, downloaded once and checked against state.json. */
async function vanillaSwf (deploy, state) {
  const file = path.join(WORK_ROOT, 'vanilla', `${deploy}.swf`)
  if (!fs.existsSync(file)) {
    const url = `${CONTENT_URL}/${deploy}/ajclient.swf`
    log(`downloading ${url}`)
    const res = await fetch(url)
    if (!res.ok) fail(`download failed: HTTP ${res.status} for ${url}. Pass --base-swf if AJ no longer hosts it.`)
    const buf = Buffer.from(await res.arrayBuffer())
    if (!['FWS', 'CWS', 'ZWS'].includes(buf.subarray(0, 3).toString('latin1'))) fail(`${url} is not a SWF`)
    fs.mkdirSync(path.dirname(file), { recursive: true })
    fs.writeFileSync(file, buf)
  }
  const hash = sha256(file)
  state.vanilla = state.vanilla || {}
  if (state.vanilla[deploy] && state.vanilla[deploy] !== hash) {
    fail(`${rel(file)} doesn't match the deploy ${deploy} hash in state.json. Delete it to re-download.`)
  }
  state.vanilla[deploy] = hash
  return file
}

function javaBin (name) {
  const exe = process.platform === 'win32' ? `${name}.exe` : name
  return process.env.JAVA_HOME ? path.join(process.env.JAVA_HOME, 'bin', exe) : name
}

function ffdecClasspath () {
  return [path.join(FFDEC_HOME, 'lib', '*'), path.join(FFDEC_HOME, 'ffdec.jar'), TOOL_DIR].join(path.delimiter)
}

function run (cmd, args, { capture = false, cwd } = {}) {
  const res = spawnSync(cmd, args, {
    cwd,
    encoding: 'utf8',
    maxBuffer: 256 * 1024 * 1024,
    stdio: capture ? ['ignore', 'pipe', 'pipe'] : 'inherit'
  })
  if (res.error) fail(`could not run ${cmd}: ${res.error.message}`)
  return res
}

function ensureTool () {
  if (!fs.existsSync(path.join(FFDEC_HOME, 'ffdec.jar'))) fail(`FFDec not found at ${FFDEC_HOME} (set FFDEC_HOME)`)
  const src = path.join(TOOL_DIR, 'AjUpdateTool.java')
  const cls = path.join(TOOL_DIR, 'AjUpdateTool.class')
  if (fs.existsSync(cls) && fs.statSync(cls).mtimeMs >= fs.statSync(src).mtimeMs) return
  log('compiling AjUpdateTool.java')
  const res = run(javaBin('javac'), ['-nowarn', '-cp', ffdecClasspath(), '-d', TOOL_DIR, src], { capture: true })
  if (res.status !== 0) fail(`javac failed:\n${res.stdout}${res.stderr}`)
}

// cwd = tmpdir so a JVM crash log doesn't land in the repo.
function javaTool (args, { capture = false } = {}) {
  return run(javaBin('java'), ['-Xmx1600m', '-cp', ffdecClasspath(), 'AjUpdateTool', ...args], { capture, cwd: os.tmpdir() })
}

// Exports are cached by SWF hash. One export at a time, single-threaded:
// parallel FFDec exports have come out truncated, and its default thread pool
// can run the JVM out of native memory.
function exportScripts (swf) {
  const hash = sha256(swf)
  const outDir = path.join(WORK_ROOT, 'exports', hash.slice(0, 16))
  const scripts = path.join(outDir, 'scripts')
  const done = path.join(outDir, '.export-done')
  if (fs.existsSync(done)) return scripts
  fs.rmSync(outDir, { recursive: true, force: true })
  fs.mkdirSync(outDir, { recursive: true })
  log(`exporting scripts from ${rel(swf)}`)
  const cli = path.join(FFDEC_HOME, process.platform === 'win32' ? 'ffdec-cli.exe' : 'ffdec.sh')
  const res = run(cli, ['-config', 'parallelSpeedUp=0', '-export', 'script', outDir, swf], { capture: true, cwd: outDir })
  if (res.status !== 0 || !fs.existsSync(scripts)) fail(`FFDec export failed for ${swf}:\n${res.stdout}${res.stderr}`)
  fs.writeFileSync(done, swf)
  return scripts
}

function nonScriptTags (swf) {
  const res = javaTool(['tags', swf], { capture: true })
  if (res.status !== 0) fail(`reading tags failed for ${swf}:\n${res.stdout}${res.stderr}`)
  const tags = new Map()
  for (const line of res.stdout.split(/\r?\n/)) {
    const [name, hash] = line.split('\t')
    if (hash && !IGNORED_TAGS.test(name)) tags.set(name, hash)
  }
  return tags
}

function diffTags (base, theirs) {
  const out = []
  for (const [name, hash] of theirs) {
    if (!base.has(name)) out.push(`${name} added`)
    else if (base.get(name) !== hash) out.push(`${name} changed`)
  }
  for (const name of base.keys()) if (!theirs.has(name)) out.push(`${name} removed`)
  return out
}

function scriptPath (dir, relPath) {
  return path.join(dir, ...relPath.split('/'))
}

function readIfExists (file) {
  return file && fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null
}

function writeCrlf (file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true })
  fs.writeFileSync(file, normalize(text).replace(/\n/g, '\r\n'))
}

function timestamp () {
  return new Date().toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 15)
}

/**
 * Brings one client from its recorded deploy to `deploy`.
 * Returns { ok, conflicts: [files] }.
 */
async function updateTarget (name, deploy, state, opts) {
  const target = TARGETS[name]
  const fromDeploy = state.targets[name].deploy
  const workDir = path.join(WORK_ROOT, `${name}-${fromDeploy}-to-${deploy}`)
  const conflictDir = path.join(workDir, 'conflicts')
  const mergedDir = path.join(workDir, 'merged')
  log(`--- ${name}: deploy ${fromDeploy} -> ${deploy} (${rel(target.swf)})`)

  const baseSwf = opts.baseSwf || await vanillaSwf(fromDeploy, state)
  const newSwf = await vanillaSwf(deploy, state)
  const oursSwf = opts.oursSwf || target.swf
  const baseScripts = exportScripts(baseSwf)
  const theirsScripts = exportScripts(newSwf)
  const oursScripts = exportScripts(oursSwf)
  const ours = listScripts(oursScripts)

  const warnings = []
  let classes
  if (target.mode === 'patch') {
    const tagChanges = diffTags(nonScriptTags(baseSwf), nonScriptTags(newSwf))
    if (tagChanges.length) {
      warnings.push(`AJ changed non-script tags, which are not ported automatically: ${tagChanges.join(', ')}. ` +
        'Compare them in FFDec and copy them over by hand if needed.')
    }
    const diff = diffExports(baseScripts, theirsScripts)
    for (const r of diff.removed) warnings.push(`AJ removed ${classNameFromPath(r)}; it was left in our client.`)
    for (const r of diff.unnamedChanged) warnings.push(`AJ changed an unnamed script (${r} in the AJ export); check it by hand.`)
    log(`AJ changed ${diff.changed.length} classes and added ${diff.added.length}`)
    classes = [...diff.changed, ...diff.added]
  } else {
    classes = target.classes.map(c => c.split('.').join('/') + '.as')
  }

  const labels = ['strawberry-jam', `aj-${fromDeploy}`, `aj-${deploy}`]
  const results = []
  for (const r of classes) {
    const source = opts.useSources
      ? target.sourceDirs.map(d => scriptPath(d, r)).find(f => fs.existsSync(f)) || null
      : null
    const res = resolveClass({
      base: readIfExists(scriptPath(baseScripts, r)) || '',
      theirs: readIfExists(scriptPath(theirsScripts, r)) || '',
      ours: readIfExists(source || ours.get(r)),
      resolvedText: readIfExists(scriptPath(conflictDir, r)),
      labels,
      tmpDir: path.join(workDir, 'tmp')
    })
    if (res.action === 'conflict' && !fs.existsSync(scriptPath(conflictDir, r))) writeCrlf(scriptPath(conflictDir, r), res.text)
    results.push({ rel: r, fqcn: classNameFromPath(r), source, ...res })
  }
  fs.rmSync(path.join(workDir, 'tmp'), { recursive: true, force: true })

  for (const r of results) log(`  ${r.action.padEnd(9)} ${r.fqcn}${r.source ? '  (scripts/patches/src)' : ''}`)
  for (const w of warnings) log(`WARNING: ${w}`)

  const conflicts = results.filter(r => r.action === 'conflict')
  if (conflicts.length) {
    log(`${conflicts.length} class(es) in ${name} need a hand merge. Edit these files, remove every conflict marker`)
    log(`(<<<<<<< strawberry-jam / ||||||| ${labels[1]} / ======= / >>>>>>> ${labels[2]}), then run again:`)
    for (const c of conflicts) log(`  ${scriptPath(conflictDir, c.rel)}`)
    return { ok: false }
  }

  // patch: our SWF + every class that isn't already right.
  // overlay: AJ's SWF + our hook classes (skip any we no longer differ on).
  const toCompile = target.mode === 'patch'
    ? results.filter(r => r.action !== 'unchanged')
    : results.filter(r => r.action !== 'theirs')
  const inputSwf = target.mode === 'patch' ? oursSwf : newSwf
  const builtSwf = path.join(workDir, 'ajclient.swf')
  if (toCompile.length) {
    fs.rmSync(mergedDir, { recursive: true, force: true })
    for (const r of toCompile) writeCrlf(scriptPath(mergedDir, r.rel), r.text)
    const classList = path.join(workDir, 'classes.txt')
    fs.writeFileSync(classList, toCompile.map(r => r.fqcn).join('\n') + '\n')
    log(`compiling ${toCompile.length} class(es)`)
    const res = javaTool(['apply', inputSwf, builtSwf, mergedDir, classList])
    if (res.status !== 0) {
      log(`compiling failed (see COMPILE ERROR above). Fix the class in ${rel(mergedDir)}, save the fixed file ` +
        `to ${rel(conflictDir)}/<same path> (it is then used as is), and run again.`)
      return { ok: false }
    }
  } else {
    fs.copyFileSync(inputSwf, builtSwf)
  }

  const report = [
    `# ${name}: AJ deploy ${fromDeploy} -> ${deploy}`,
    '',
    ...results.map(r => `- ${r.action}: \`${r.fqcn}\``),
    ...(warnings.length ? ['', '## Warnings', '', ...warnings.map(w => `- ${w}`)] : [])
  ].join('\n') + '\n'
  fs.writeFileSync(path.join(workDir, 'REPORT.md'), report)

  if (!opts.install) {
    log(`built ${rel(builtSwf)} (--no-install: nothing else changed)`)
    return { ok: true }
  }
  if (!opts.oursSwf) {
    const backup = path.join(workDir, `backup-${timestamp()}.swf`)
    fs.copyFileSync(target.swf, backup)
    fs.copyFileSync(builtSwf, target.swf)
    log(`updated ${rel(target.swf)} (previous copy: ${rel(backup)})`)
  } else {
    fs.copyFileSync(builtSwf, opts.oursSwf)
    log(`updated ${rel(opts.oursSwf)}`)
  }
  const touched = toCompile.filter(r => r.source)
  for (const r of touched) writeCrlf(r.source, r.text)
  if (touched.length) log(`updated sources: ${touched.map(r => rel(r.source)).join(', ')}`)
  log(`report: ${rel(path.join(workDir, 'REPORT.md'))}`)
  state.targets[name] = { deploy, updatedAt: new Date().toISOString() }
  writeState(state)
  return { ok: true }
}

async function main () {
  const opts = parseArgs(process.argv.slice(2))
  const state = readState()
  const deploy = opts.deploy || await fetchLiveDeploy()

  const stale = opts.targets.filter(t => opts.force || state.targets[t].deploy !== deploy)
  for (const t of opts.targets) log(`${t}: synced to deploy ${state.targets[t].deploy}; AJ is on ${deploy}`)
  if (opts.check) {
    if (!stale.length) { log('up to date'); return }
    log(`Run "npm run aj:update" to port deploy ${deploy}.`)
    process.exitCode = 1
    return
  }
  if (!stale.length) { log('up to date (use --force to rebuild anyway)'); return }

  ensureTool()
  let ok = true
  for (const t of stale) {
    const res = await updateTarget(t, deploy, state, opts)
    ok = ok && res.ok
  }
  if (!ok) { process.exitCode = 1; return }
  if (opts.install) {
    log(`Done. Test in game, then ship it like any client release ` +
      `(copy ajclient.swf to options/vX.Y.Z.swf, bump LATEST_SWF_FILE).`)
  }
}

main().catch(err => {
  console.error(`\n[aj-update] ${err instanceof UpdateError ? err.message : err.stack}`)
  process.exitCode = 2
})
