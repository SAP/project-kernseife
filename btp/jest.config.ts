import type { Config } from 'jest';
import { createDefaultPreset } from 'ts-jest';

const config: Config = {
  ...createDefaultPreset({ tsconfig: './tsconfig.test.json' }),
  modulePathIgnorePatterns: ['<rootDir>/gen/']
};

export default config;
