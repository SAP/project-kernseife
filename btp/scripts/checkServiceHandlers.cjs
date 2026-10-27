const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');

const check = async () => {
  const bundle = path.resolve(process.argv[2] || 'gen/srv');
  process.chdir(bundle);
  const bundledRequire = createRequire(path.join(bundle, 'package.json'));
  const cds = bundledRequire('@sap/cds');
  const ServiceFactory = bundledRequire('@sap/cds/lib/srv/factory');
  cds.root = bundle;
  const model = await cds.load('srv/csn.json');
  cds.model = model;

  const handlers = {
    AdminService: 'admin-service.js',
    ClassificationService: 'classification-service.js',
    DevelopmentService: 'development-service.js',
    AnalyticsService: 'analytics-service.js'
  };
  for (const [name, file] of Object.entries(handlers)) {
    const service = await new ServiceFactory(name, model, {});
    assert.equal(
      typeof service.options.impl,
      'function',
      `${name} did not discover its custom implementation`
    );
    assert.equal(
      fs.realpathSync(service._source),
      fs.realpathSync(path.join(bundle, 'srv', file)),
      `${name} loaded an implementation outside its packaged service directory`
    );
    await ServiceFactory.init(service);
  }
  console.log(
    'All four packaged custom service handlers were discovered and initialized.'
  );
};

check().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
