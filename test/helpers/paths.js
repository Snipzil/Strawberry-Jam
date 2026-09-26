const fs = require('fs')
const path = require('path')

const ROOT = path.resolve(__dirname, '..', '..')

const readJson = (file) => JSON.parse(fs.readFileSync(file, 'utf8'))

const findFiles = (dir, predicate, out = []) => {
  if (!fs.existsSync(dir)) return out
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      if (entry.name !== 'node_modules') findFiles(full, predicate, out)
    } else if (predicate(full)) {
      out.push(full)
    }
  }
  return out
}

module.exports = { ROOT, readJson, findFiles }
