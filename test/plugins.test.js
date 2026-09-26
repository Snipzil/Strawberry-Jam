const { describe, test } = require('node:test')
const assert = require('node:assert')
const fs = require('fs')
const path = require('path')
const { builtinModules } = require('module')
const Ajv = require('ajv')
const { PluginManager: LivePluginManager } = require('live-plugin-manager')
const { ConfigurationSchema } = require('../src/managers/plugin/PluginManager')
const { ROOT, readJson, findFiles } = require('./helpers/paths')

const PLUGINS_DIR = path.join(ROOT, 'plugins')
const PACKAGES_DIR = path.join(ROOT, 'plugin_packages')

// Same Ajv options as PluginManager so defaults are applied identically.
const validate = new Ajv({ useDefaults: true }).compile(ConfigurationSchema)

const plugins = findFiles(PLUGINS_DIR, (f) => path.basename(f) === 'plugin.json').map((file) => {
  const dir = path.dirname(file)
  const raw = readJson(file)
  const configuration = structuredClone(raw.default || raw)
  const valid = validate(configuration)
  return { file, dir, label: path.relative(PLUGINS_DIR, dir), configuration, valid, errors: validate.errors }
})

const ALLOWED_BARE = new Set([...builtinModules, 'electron'])
const bareRequires = (source) =>
  [...source.matchAll(/require\(\s*['"]([^'"]+)['"]\s*\)/g)].map((m) => m[1])

test('bundled plugins exist', () => {
  assert.ok(plugins.length > 0, `no plugin.json found under ${PLUGINS_DIR}`)
})

test('plugin names are unique', () => {
  const seen = new Map()
  for (const { configuration, label } of plugins) {
    assert.ok(!seen.has(configuration.name), `"${configuration.name}" used by both ${seen.get(configuration.name)} and ${label}`)
    seen.set(configuration.name, label)
  }
})

for (const plugin of plugins) {
  describe(`plugin: ${plugin.label}`, () => {
    test('plugin.json passes the loader schema', () => {
      assert.ok(plugin.valid, JSON.stringify(plugin.errors))
    })

    test('type is "game" or "ui"', () => {
      assert.ok(['game', 'ui'].includes(plugin.configuration.type), `got "${plugin.configuration.type}"`)
    })

    test('main entry exists', () => {
      assert.ok(fs.existsSync(path.join(plugin.dir, plugin.configuration.main)), `missing ${plugin.configuration.main}`)
    })

    if (plugin.configuration.type === 'game') {
      test('main entry loads and exports a constructor', () => {
        const exported = require(path.join(plugin.dir, plugin.configuration.main))
        assert.strictEqual(typeof exported, 'function')
      })
    }

    const jsFiles = findFiles(plugin.dir, (f) => f.endsWith('.js'))
    for (const jsFile of jsFiles) {
      test(`${path.relative(plugin.dir, jsFile)} only requires builtins, electron, local files or declared deps`, () => {
        const declared = new Set(Object.keys(plugin.configuration.dependencies))
        for (const spec of bareRequires(fs.readFileSync(jsFile, 'utf8'))) {
          if (spec.startsWith('.')) {
            assert.doesNotThrow(() => require.resolve(path.resolve(path.dirname(jsFile), spec)), `unresolvable ${spec}`)
            continue
          }
          const name = spec.startsWith('@') ? spec.split('/').slice(0, 2).join('/') : spec.split('/')[0]
          assert.ok(ALLOWED_BARE.has(name) || ALLOWED_BARE.has(name.replace(/^node:/, '')) || declared.has(name),
            `requires "${spec}" without declaring it; downloaded plugins cannot resolve the app's node_modules`)
        }
      })
    }

    const deps = Object.keys(plugin.configuration.dependencies)
    if (deps.length > 0) {
      // Runs the real installer with the network blocked; it succeeds only if plugin_packages plus host node_modules cover the tree.
      test('declared dependencies install offline from plugin_packages', async () => {
        const dependencyManager = new LivePluginManager({ pluginsPath: PACKAGES_DIR })
        for (const [name, range] of Object.entries(plugin.configuration.dependencies)) {
          await assert.doesNotReject(dependencyManager.install(name, range), `${name}@${range} is not available offline; install it once while online`)
        }
      })
    }
  })
}
