module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/test/**/*.test.js', '**/test/**/*.spec.js'],
  collectCoverageFrom: [
    '**/*.js',
    '!script/**/*',
    '!node_modules/**/*',
    '!coverage/**/*',
    '!**/*.test.js',
    '!**/*.spec.js',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
  verbose: true,
  testTimeout: 10000,
};
