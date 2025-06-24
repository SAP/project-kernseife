import type { JestConfigWithTsJest } from 'ts-jest';

const jestConfig: JestConfigWithTsJest = {
  // Indicates whether the coverage information should be collected while executing the test
  collectCoverage: true,

  // An array of glob patterns indicating a set of files for which coverage information should be collected
  collectCoverageFrom: [
    '**/srv/**/*.ts',
    '!**/test/**/*.ts',
    '!jest.config.ts',
  ],

  // The directory where Jest should output its coverage files
  coverageDirectory: 'coverage/',

  // A list of reporter names that Jest uses when writing coverage reports
  coverageReporters: ['lcov', 'text'],

  // An object that configures minimum threshold enforcement for coverage results
  coverageThreshold: {
    global: {
      branches: 50,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },

  // An array of file extensions your modules use
  moduleFileExtensions: [
    'js',
    'mjs',
    'cjs',
    'jsx',
    'ts',
    'mts',
    'cts',
    'tsx',
    'json',
    'node'
  ],

  // An array of regexp pattern strings, matched against all module paths before considered 'visible' to the module loader
  modulePathIgnorePatterns: ['<rootDir>/gen/', '<rootDir>/bower_components/'],

  // A preset that is used as a base for Jest's configuration
  preset: 'ts-jest',
  transform: {
    '^.+\\.ts$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }]
  },

  // Use this configuration option to add custom reporters to Jest
  reporters: [
    'default'
  ],

  // A list of paths to modules that run some code to configure or set up the testing framework before each test
  setupFilesAfterEnv: ['./test/jest.setup.ts'],

  // The test environment that will be used for testing
  testEnvironment: 'node',

  // The glob patterns Jest uses to detect test files
  testMatch: ['**/test/**/*.test.ts'],

  // An array of regexp pattern strings that are matched against all test paths, matched tests are skipped
  testPathIgnorePatterns: ['/node_modules/', '/gen/', '/api/gen/'],

  // This option sets the URL for the jsdom environment. It is reflected in properties such as location.href
  testEnvironmentOptions: {
    url: 'http://localhost'
  },

  // Indicates whether each individual test should be reported during the run
  verbose: false,

  maxWorkers: 4,

  // Timeouts
  testTimeout: 20000,

  coveragePathIgnorePatterns: [
    'node_modules',
    'test-config',
    'interfaces',
    'jestGlobalMocks.ts',
    '<rootDir>/srv/events/def/',
    '.mock.ts'
  ]
};

export default jestConfig;