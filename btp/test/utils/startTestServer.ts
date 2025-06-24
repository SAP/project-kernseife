import cds from '@sap/cds';

export default () => {
  process.env.NO_TELEMETRY = 'true';

  return cds.test(
    'serve',
    '--with-mocks',
    '--in-memory',
    '--project',
    './',
    '--profile',
    'test'
  );
};