module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  env: {
    es6: true,
    node: true
  },
  extends: ['eslint:recommended', 'google'],
  rules: {
    'require-jsdoc': 0,
    'max-len': ['error', { 'code': 120 }]
  }
};
