import cds, { deploy } from '@sap/cds';
import type { DatabaseService } from '@sap/cds';
import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  jest
} from '@jest/globals';
import * as connector from '../srv/features/btp-connector-feature';
import type {
  DevelopmentObjectImport,
  FindingImport,
  ProjectImport
} from '../srv/types/imports';
import { importFindingsBTP } from '../srv/features/developmentObject-feature';

jest.mock('../srv/features/btp-connector-feature', () => ({
  getDestinationBySystemId: jest.fn(),
  getProject: jest.fn(),
  getFindingsCount: jest.fn(),
  getFindings: jest.fn(),
  getDevelopmentObjectsCount: jest.fn(),
  getDevelopmentObjects: jest.fn(),
  getExemptionsCount: jest.fn(),
  getExemptions: jest.fn()
}));

const object = (index: number): DevelopmentObjectImport => ({
  projectId: 'PROJECT',
  runId: 'RUN',
  objectType: 'CLAS',
  objectName: `ZCLASS${index}`,
  subType: '',
  devClass: 'ZPKG',
  softwareComponent: 'TEST',
  languageVersion: '5',
  contactPerson: '',
  _findings: [],
  _metrics: {
    projectId: 'PROJECT',
    objectType: 'CLAS',
    objectName: `ZCLASS${index}`,
    difficulty: 0,
    numberOfChanges: 0
  },
  _usages: [
    {
      entry_point_type: 'PROG',
      entry_point_name: 'ZENTRY',
      obj_type: 'CLAS',
      obj_name: `ZCLASS${index}`,
      counter: index + 1,
      last_used: '2026-10-01T12:00:00Z'
    }
  ]
});
const firstPage = Array.from({ length: 100 }, (_, index) => object(index));

describe('BTP import interruption/restart (#82)', () => {
  let database: DatabaseService;
  let importId: string;

  beforeAll(async () => {
    database = await deploy(await cds.load('db/schema.cds'))
      .to('sqlite::memory:');
  });
  beforeEach(async () => {
    jest.resetAllMocks();
    for (const entity of [
      'Imports',
      'FindingRecords',
      'DevelopmentObjects',
      'HistoricDevelopmentObjects',
      'DevelopmentObjectFindings',
      'DevelopmentObjectVersions',
      'DevelopmentObjectUsages',
      'DevelopmentObjectUsageImports'
    ]) {
      await database.run(cds.ql.DELETE.from(`kernseife.db.${entity}`));
    }
    importId = cds.utils.uuid();
    await database.run(
      cds.ql.INSERT.into('kernseife.db.Imports').entries({
        ID: importId,
        systemId: 'AAA'
      })
    );
    await database.run(
      cds.ql.INSERT.into('kernseife.db.DevelopmentObjectUsages').entries([
        {
          systemId: 'AAA',
          entryPointObjectType: 'PROG',
          entryPointObjectName: 'ZOLD',
          objectType: 'CLAS',
          objectName: 'ZOLD',
          counter: 20
        },
        {
          systemId: 'BBB',
          entryPointObjectType: 'PROG',
          entryPointObjectName: 'ZOLD',
          objectType: 'CLAS',
          objectName: 'ZOLD',
          counter: 30
        }
      ])
    );
    jest
      .mocked(connector.getDestinationBySystemId)
      .mockResolvedValue('TEST_DESTINATION');
    jest
      .mocked(connector.getProject)
      .mockResolvedValue({
        projectId: 'PROJECT',
        runId: 'RUN',
        totalObjectCount: 101
      } as ProjectImport);
    jest.mocked(connector.getFindingsCount).mockResolvedValue(1);
    jest
      .mocked(connector.getFindings)
      .mockResolvedValue([
        {
          itemId: 'ITEM',
          objectType: 'CLAS',
          objectName: 'ZCLASS0',
          devClass: 'ZPKG',
          softwareComponent: 'TEST',
          refObjectType: 'CLAS',
          refObjectName: 'REFERENCE',
          messageId: 'TEST'
        } as FindingImport
      ]);
    jest.mocked(connector.getDevelopmentObjectsCount).mockResolvedValue(101);
    jest.mocked(connector.getExemptionsCount).mockResolvedValue(0);
  });
  afterAll(async () => {
    await database?.disconnect();
  });

  const runImport = (id = importId) =>
    database.tx((tx) => importFindingsBTP(id, tx));
  const current = (systemId = 'AAA') =>
    database.run(
      cds.ql.SELECT.from('kernseife.db.DevelopmentObjectUsages').where({
        systemId
      })
    );

  it('keeps the old usage snapshot after page failure, then restarts the same import from zero', async () => {
    jest
      .mocked(connector.getDevelopmentObjects)
      .mockResolvedValueOnce(firstPage)
      .mockRejectedValueOnce(new Error('socket hang up'));
    await expect(runImport()).rejects.toThrow('socket hang up');
    expect(await current()).toEqual([
      expect.objectContaining({ objectName: 'ZOLD', counter: 20 })
    ]);
    expect(
      await database.run(
        cds.ql.SELECT.from('kernseife.db.DevelopmentObjectUsageImports')
      )
    ).toHaveLength(0);

    jest
      .mocked(connector.getDevelopmentObjects)
      .mockClear()
      .mockResolvedValueOnce(firstPage)
      .mockResolvedValueOnce([object(100)]);
    jest.mocked(connector.getFindings).mockClear();
    await expect(runImport()).resolves.toMatchObject({
      message: 'Inserted 101 DevelopmentObject(s)'
    });
    expect(jest.mocked(connector.getFindings).mock.calls[0][4]).toBe(0);
    expect(
      jest
        .mocked(connector.getDevelopmentObjects)
        .mock.calls.map((call) => call[3])
    ).toEqual([0, 100]);
    expect(await current()).toHaveLength(101);
    expect(await current()).not.toContainEqual(
      expect.objectContaining({ objectName: 'ZOLD' })
    );
    expect(await current('BBB')).toEqual([
      expect.objectContaining({ objectName: 'ZOLD', counter: 30 })
    ]);
    expect(
      await database.run(
        cds.ql.SELECT.from('kernseife.db.HistoricDevelopmentObjects').where({
          version_ID: importId
        })
      )
    ).toHaveLength(101);
    expect(
      await database.run(
        cds.ql.SELECT.from('kernseife.db.FindingRecords').where({
          import_ID: importId
        })
      )
    ).toHaveLength(1);
  });

  it('allows a fresh import after a failed job and replaces the snapshot once', async () => {
    jest
      .mocked(connector.getDevelopmentObjects)
      .mockResolvedValueOnce(firstPage)
      .mockRejectedValueOnce(new Error('socket hang up'));
    await expect(runImport()).rejects.toThrow('socket hang up');
    const nextId = cds.utils.uuid();
    await database.run(
      cds.ql.INSERT.into('kernseife.db.Imports').entries({
        ID: nextId,
        systemId: 'AAA'
      })
    );
    jest
      .mocked(connector.getDevelopmentObjects)
      .mockResolvedValueOnce(firstPage)
      .mockResolvedValueOnce([object(100)]);
    await expect(runImport(nextId)).resolves.toMatchObject({
      message: 'Inserted 101 DevelopmentObject(s)'
    });
    expect(await current()).toHaveLength(101);
  });

  it('does not publish an incomplete snapshot when a counted page is empty', async () => {
    jest
      .mocked(connector.getDevelopmentObjects)
      .mockResolvedValueOnce(firstPage)
      .mockResolvedValueOnce([]);
    await expect(runImport()).rejects.toThrow(
      'Development objects page missing'
    );
    expect(await current()).toEqual([
      expect.objectContaining({ objectName: 'ZOLD', counter: 20 })
    ]);
  });

  it('keeps the old usage snapshot if a later exemptions request fails', async () => {
    jest
      .mocked(connector.getDevelopmentObjects)
      .mockResolvedValueOnce(firstPage)
      .mockResolvedValueOnce([object(100)]);
    jest
      .mocked(connector.getExemptionsCount)
      .mockRejectedValueOnce(new Error('exemptions unavailable'));
    await expect(runImport()).rejects.toThrow('exemptions unavailable');
    expect(await current()).toEqual([
      expect.objectContaining({ objectName: 'ZOLD', counter: 20 })
    ]);
  });
});
