import eslint from '@eslint/js';
import cds from '@sap/cds/eslint.config.mjs';
import cdsPlugin from '@sap/eslint-plugin-cds';
import eslintConfigPrettier from 'eslint-config-prettier';
import jest from 'eslint-plugin-jest';
import tseslint from 'typescript-eslint';

export default tseslint.config(
    {
        ignores: [
            'gen/*',
            'mta_archives/*',
            'node_modules/*',
            'app/**/dist/*',
            'app/**/test/**',
            '@cds-models'
        ]
    },
    // Typescript
    {
        files: ['**/*.ts', '**/*.js'],
        extends: [eslint.configs.recommended, ...tseslint.configs.recommended],
        rules: {
            "@typescript-eslint/no-explicit-any": "warn",
            'no-unused-vars': 'off',
            '@typescript-eslint/no-unused-vars': 'off',
            '@typescript-eslint/ban-ts-comment': 'off',
            '@typescript-eslint/no-unused-expressions': 'off',
            'no-async-promise-executor': 'off',
            'getter-return': [
                'error',
                {
                    allowImplicit: true
                }
            ],
            'no-await-in-loop': 'off',
            'no-cond-assign': ['error', 'always'],
            'no-console': 'error',
            'no-empty': [
                'warn',
                {
                    allowEmptyCatch: false
                }
            ],
            'no-extra-parens': [
                'error',
                'all',
                {
                    conditionalAssign: false,
                    enforceForArrowConditionals: false,
                    ignoreJSX: 'all',
                    nestedBinaryExpressions: false,
                    returnAssign: false
                }
            ],
            'no-inner-declarations': ['error', 'both'],
            'no-invalid-regexp': [
                'error',
                {
                    allowConstructorFlags: ['u', 'y']
                }
            ],
            'no-irregular-whitespace': [
                'error',
                {
                    skipComments: false,
                    skipRegExps: false,
                    skipStrings: false,
                    skipTemplates: false
                }
            ],
            'no-loss-of-precision': 'error',
            'no-unreachable-loop': 'error',
            'no-useless-backreference': 'error',
            'use-isnan': 2,
            'valid-typeof': [
                'error',
                {
                    requireStringLiterals: true
                }
            ],
            'accessor-pairs': 2,
            'array-callback-return': [
                'error',
                {
                    allowImplicit: true
                }
            ],
            'block-scoped-var': 'error',
            'class-methods-use-this': [
                'off',
                {
                    exceptMethods: []
                }
            ],
            curly: ['error', 'all'],
            'default-case-last': 'error',
            'default-param-last': 'error',
            'dot-location': ['off', 'object'],
            'dot-notation': [
                'off',
                {
                    allowKeywords: true
                }
            ],
            'grouped-accessor-pairs': ['error', 'getBeforeSet'],
            'guard-for-in': 'error',
            'no-alert': 'error',
            'no-caller': 'error',
            'no-constructor-return': 'error',
            'no-div-regex': 'error',
            'no-else-return': [
                'off',
                {
                    allowElseIf: false
                }
            ],
            'no-empty-function': 'error',
            'no-eval': [
                'error',
                {
                    allowIndirect: false
                }
            ],
            'no-extend-native': [
                'error',
                {
                    exceptions: ['String']
                }
            ],
            'no-extra-bind': 'error',
            'no-extra-label': 'error',
            'no-floating-decimal': 'error',
            'no-global-assign': [
                'error',
                {
                    exceptions: []
                }
            ],
            'no-implicit-coercion': 'error',
            'no-implicit-globals': 'error',
            'no-implied-eval': 'error',
            'no-iterator': 'error',
            'no-labels': [
                'error',
                {
                    allowLoop: false,
                    allowSwitch: false
                }
            ],
            'no-lone-blocks': 'error',
            'no-loop-func': 'error',
            'no-multi-spaces': [
                'error',
                {
                    ignoreEOLComments: false,
                    exceptions: {
                        BinaryExpression: false,
                        ImportDeclaration: false,
                        Property: false,
                        VariableDeclarator: false
                    }
                }
            ],
            'no-multi-str': 'error',
            'no-new': 'error',
            'no-new-func': 'error',
            'no-new-wrappers': 'off',
            'no-octal-escape': 'error',
            'no-param-reassign': [
                'off',
                {
                    props: true,
                    ignorePropertyModificationsFor: []
                }
            ],
            'no-proto': 'error',
            'no-redeclare': [
                'error',
                {
                    builtinGlobals: true
                }
            ],

            'no-return-assign': ['error', 'always'],
            'no-script-url': 'error',
            'no-self-assign': [
                'error',
                {
                    props: true
                }
            ],
            'no-self-compare': 'error',
            'no-sequences': 'off',
            'no-unmodified-loop-condition': 'error',
            'no-unused-expressions': [
                'off',
                {
                    allowShortCircuit: true,
                    allowTernary: true,
                    allowTaggedTemplates: true
                }
            ],
            'no-useless-return': 'error',
            'no-void': 'error',
            'prefer-promise-reject-errors': [
                'error',
                {
                    allowEmptyReject: false
                }
            ],
            'prefer-regex-literals': 'error',
            radix: ['error', 'always'],
            'vars-on-top': 'error',
            'wrap-iife': [
                'error',
                'inside',
                {
                    functionPrototypeMethods: true
                }
            ],
            yoda: [
                'error',
                'never',
                {
                    exceptRange: true,
                    onlyEquality: false
                }
            ],
            strict: ['off', 'function'],
            'no-label-var': 'error',
            'no-restricted-globals': 'error',
            'no-shadow': [
                'error',
                {
                    builtinGlobals: false,
                    hoist: 'functions',
                    allow: []
                }
            ],
            'no-undef': [
                'error',
                {
                    typeof: true
                }
            ],
            'no-undef-init': 'error',
            'no-use-before-define': 'warn',
            'callback-return': ['error', ['callback', 'next']],
            'global-require': 'off',
            'handle-callback-err': ['error', 'err'],
            'no-buffer-constructor': 'error',
            'no-mixed-requires': [
                'error',
                {
                    grouping: true,
                    allowCall: false
                }
            ],
            'no-new-require': 'error',
            'no-path-concat': 'error',
            'no-process-env': 'off',
            'no-process-exit': 'error',
            'no-sync': [
                'off',
                {
                    allowAtRootLevel: false
                }
            ],
            'array-bracket-spacing': [
                'off',
                'always',
                {
                    singleValue: true,
                    objectsInArrays: false,
                    arraysInArrays: false
                }
            ],
            'block-spacing': ['error', 'always'],
            'brace-style': [
                'error',
                '1tbs',
                {
                    allowSingleLine: false
                }
            ],
            camelcase: 'off',
            'capitalized-comments': [
                'off',
                'always',
                {
                    ignoreInlineComments: false,
                    ignoreConsecutiveComments: true
                }
            ],
            'comma-dangle': ['error', 'never'],
            'comma-spacing': [
                'error',
                {
                    before: false,
                    after: true
                }
            ],
            'comma-style': ['error', 'last'],
            'computed-property-spacing': 'error',
            'consistent-this': ['error', 'that'],
            'eol-last': ['off'],
            'func-call-spacing': ['error', 'never'],
            'func-style': ['error', 'expression'],
            'function-call-argument-newline': ['error', 'consistent'],
            'function-paren-newline': ['off'],
            'no-constant-condition': 'off',
            'id-length': [
                'off',
                {
                    min: 2,
                    properties: 'always',
                    exceptions: ['_', 'i', 'j', 't', 'x', 'y', 'z', 'a', 'b']
                }
            ]
        },
        ignores: ['node_modules', 'gen', 'app'],
        languageOptions: {
            globals: {
                sap: 'readonly',
                jQuery: 'readonly',
                moment: 'readonly',
                BackgroundGeolocation: 'readonly',
                cordova: 'readonly',
                openui5: 'readonly',
                google: 'readonly',
                applicationContext: 'writable',
                smpHelper: 'readonly',
                StatusBar: 'readonly',
                Promise: 'readonly',
                Set: 'readonly',
                Map: 'readonly',
                tinymce: 'readonly',
                QUnit: 'readonly',
                SELECT: true,
                INSERT: true,
                UPDATE: true,
                DELETE: true,
                CREATE: true,
                DROP: true,
                cds: true
            }
        }
    },

    // CDS
    ...cds.recommended,
    {
        ...cdsPlugin.configs.recommended,
        files: ['*.cds', '**/*.cds'],
        plugins: {
            '@sap/cds': cdsPlugin
        },
        rules: {
            '@sap/cds/start-entities-uppercase': 'warn',
            '@sap/cds/start-elements-lowercase': 'warn'
        }
    },

    // Prettier
    eslintConfigPrettier,

    // Jest,
    jest.configs['flat/recommended'],
    {
        ignores: [
            'node_modules',
            'gen',
            '@cds-models',
            '.husky',
            '.temp',
            'reports',
            'coverage',
            '*.http',
            '*.md',
            '*.yaml',
            '*.hdbview',
            '*.hdbprocedure',
            '*.hdbtable',
            '*.hdbtabledata',
            '*.hdbcollection',
            '*.csv',
            '*.properties',
            '*.svg',
            '*.tpl',
            '*.txt'
        ]
    }
);