module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Commit bodies are written as unwrapped paragraphs/bullets
    'body-max-line-length': [0],
    'footer-max-line-length': [0],
    // Warn only, so single-plugin scopes (e.g. `den-shop`) still pass
    'scope-enum': [1, 'always', [
      'ui', 'client', 'modmenu', 'patches', 'plugins',
      'networking', 'api', 'assets', 'release', 'deps', 'ci', 'build'
    ]],
    'scope-case': [2, 'always', 'kebab-case']
  }
}
