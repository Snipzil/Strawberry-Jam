const js = require('@eslint/js')
const globals = require('globals')

module.exports = [
  {
    ignores: [
      'node_modules/**',
      'build/**',
      'dev/**',
      'plugin_packages/**',
      'assets/scripts/**',
      'assets/client/**',
      'assets/styles/**'
    ]
  },
  js.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2024,
      sourceType: 'commonjs',
      globals: {
        ...globals.browser,
        ...globals.node,
        $: 'readonly',
        jQuery: 'readonly',
        jam: 'readonly',
        twemoji: 'readonly',
        Sortable: 'readonly',
        Popper: 'readonly'
      }
    },
    rules: {
      'no-unused-vars': ['error', { args: 'none', caughtErrors: 'none' }],
      'no-empty': ['error', { allowEmptyCatch: true }],
      'no-prototype-builtins': 'off',
      'no-inner-declarations': 'off',
      'no-control-regex': 'off',
      'preserve-caught-error': 'off',
      'no-var': 'error',
      'prefer-const': 'error'
    }
  }
]
