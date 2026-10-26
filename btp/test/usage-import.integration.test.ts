import cds, { deploy } from '@sap/cds';
import type { DatabaseService } from '@sap/cds';
import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it
} from '@jest/globals';
import {
  clearUsageImport,
  publishUsageImport,
  stageUsageImport
} from '../srv/features/usage-import-feature';

const CURRENT = 'kernseife.db.DevelopmentObjectUsages';
const STAGING = 'kernseife.db.DevelopmentObjectUsageImports';
const usage = (objectName = 'ZOBJECT', counter = 10) => ({
  entryPointObjectType: 'PROG',
  entryPointObjectName: 'ZENTRY',
  objectType: 'CLAS',
  objectName,
  counter,
  lastUsed: '2026-10-01T12:00:00Z'
});

describe('usage snapshots (#82)', () => {
  let database: DatabaseService;
  let importId: string;

  beforeAll(async () => {
    database = await deploy(await cds.load('db/schema.cds'))
      .to('sqlite::memory:');
  });
  beforeEach(async () => {
    importId = cds.utils.uuid();
    await database.run(cds.ql.DELETE.from(CURRENT));
    await database.run(cds.ql.DELETE.from(STAGING));
    await database.run(cds.ql.DELETE.from('kernseife.db.DevelopmentObjects'));
  });
  afterAll(async () => {
    await database?.disconnect();
  });

  it('deduplicates snapshot values within and across pages without adding counters', async () => {
    await database.tx(async (tx) => {
      await stageUsageImport(tx, importId, 'AAA', [usage(), usage()]);
      await stageUsageImport(tx, importId, 'AAA', [usage('ZOBJECT', 12)]);
    });
    expect(await database.run(cds.ql.SELECT.from(CURRENT))).toHaveLength(0);
    await database.tx((tx) => publishUsageImport(tx, importId, 'AAA'));
    expect(await database.run(cds.ql.SELECT.from(CURRENT))).toEqual([
      { ...usage('ZOBJECT', 12), systemId: 'AAA' }
    ]);
    expect(await database.run(cds.ql.SELECT.from(STAGING))).toHaveLength(0);
  });

  it('replaces only the selected system, keeping identical keys in other systems', async () => {
    await database.run(
      cds.ql.INSERT.into(CURRENT).entries([
        { ...usage(), systemId: 'AAA' },
        { ...usage(), systemId: 'BBB' }
      ])
    );
    await database.tx(async (tx) => {
      await stageUsageImport(tx, importId, 'AAA', [usage('ZNEW')]);
      await publishUsageImport(tx, importId, 'AAA');
    });
    expect(
      await database.run(cds.ql.SELECT.from(CURRENT).where({ systemId: 'AAA' }))
    ).toEqual([{ ...usage('ZNEW'), systemId: 'AAA' }]);
    expect(
      await database.run(cds.ql.SELECT.from(CURRENT).where({ systemId: 'BBB' }))
    ).toEqual([{ ...usage(), systemId: 'BBB' }]);
  });

  it('discards committed partial pages on restart without exposing them', async () => {
    await database.run(
      cds.ql.INSERT.into(CURRENT).entries({ ...usage(), systemId: 'AAA' })
    );
    const otherImport = cds.utils.uuid();
    await database.tx(async (tx) => {
      await stageUsageImport(tx, importId, 'AAA', [usage('ZPARTIAL')]);
      await stageUsageImport(tx, otherImport, 'AAA', [usage('ZOTHER')]);
    });
    expect(await database.run(cds.ql.SELECT.from(CURRENT))).toEqual([
      { ...usage(), systemId: 'AAA' }
    ]);
    await database.tx(async (tx) => {
      await clearUsageImport(tx, importId, 'AAA');
      await stageUsageImport(tx, importId, 'AAA', [usage('ZRESTARTED')]);
      await publishUsageImport(tx, importId, 'AAA');
    });
    expect(await database.run(cds.ql.SELECT.from(CURRENT))).toEqual([
      { ...usage('ZRESTARTED'), systemId: 'AAA' }
    ]);
    expect(await database.run(cds.ql.SELECT.from(STAGING))).toHaveLength(1);
  });

  it('publishes an empty snapshot by removing stale usages only for that system', async () => {
    await database.run(
      cds.ql.INSERT.into(CURRENT).entries([
        { ...usage(), systemId: 'AAA' },
        { ...usage(), systemId: 'BBB' }
      ])
    );
    await database.tx((tx) => publishUsageImport(tx, importId, 'AAA'));
    expect(await database.run(cds.ql.SELECT.from(CURRENT))).toEqual([
      { ...usage(), systemId: 'BBB' }
    ]);
  });

  it('rolls back publication together, restoring the previous snapshot and staging', async () => {
    await database.run(
      cds.ql.INSERT.into(CURRENT).entries({ ...usage(), systemId: 'AAA' })
    );
    await database.tx((tx) =>
      stageUsageImport(tx, importId, 'AAA', [usage('ZNEW')])
    );
    await expect(
      database.tx(async (tx) => {
        await publishUsageImport(tx, importId, 'AAA');
        throw new Error('commit interrupted');
      })
    ).rejects.toThrow('commit interrupted');
    expect(await database.run(cds.ql.SELECT.from(CURRENT))).toEqual([
      { ...usage(), systemId: 'AAA' }
    ]);
    expect(await database.run(cds.ql.SELECT.from(STAGING))).toHaveLength(1);
  });

  it('scopes usage navigation to the parent object system', async () => {
    await database.run(
      cds.ql.INSERT.into(CURRENT).entries([
        { ...usage(), systemId: 'AAA' },
        { ...usage('ZOBJECT', 99), systemId: 'BBB' }
      ])
    );
    await database.run(
      cds.ql.INSERT.into('kernseife.db.DevelopmentObjects').entries({
        objectType: 'CLAS',
        objectName: 'ZOBJECT',
        devClass: 'ZPKG',
        systemId: 'AAA'
      })
    );
    const result = await database.run(
      cds.ql.SELECT.one
        .from('kernseife.db.DevelopmentObjects')
        .columns('objectName', {
          ref: ['usageList'],
          expand: [{ ref: ['counter'] }, { ref: ['systemId'] }]
        })
    );
    expect(result.usageList).toEqual([{ counter: 10, systemId: 'AAA' }]);
  });
});
