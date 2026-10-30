import cds, { deploy } from '@sap/cds';
import type { DatabaseService } from '@sap/cds';
import type { Import } from '#cds-models/kernseife/db';
import { Readable } from 'node:stream';
import papa from 'papaparse';
import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  jest
} from '@jest/globals';
import {
  importFindingsBTP,
  importFindingsCSV
} from '../srv/features/developmentObject-feature';
import * as connector from '../srv/features/btp-connector-feature';
import type {
  DevelopmentObjectImport,
  FindingImport,
  ProjectImport
} from '../srv/types/imports';

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

const languages = [
  { objectName: 'ZCLOUD', languageVersion: '5', expectedLevel: 'A' },
  { objectName: 'ZKEYUSER', languageVersion: '2', expectedLevel: 'B' },
  { objectName: 'ZSTANDARD', languageVersion: 'X', expectedLevel: 'B' }
];
const findings: FindingImport[] = languages.map((entry) => ({
  projectId: 'PROJECT',
  runId: 'RUN',
  itemId: entry.objectName,
  objectType: 'CLAS',
  objectName: entry.objectName,
  devClass: 'ZPKG',
  softwareComponent: 'TEST',
  messageId: entry.languageVersion,
  checksumVersion: 0,
  checksumValue: 0,
  refObjectType: '',
  refObjectName: '',
  refApplicationComponent: '',
  refSoftwareComponent: '',
  refDevClass: ''
}));

describe('language-only object imports (#91)', () => {
  let database: DatabaseService;
  let importId: string;

  beforeAll(async () => {
    database = await deploy(await cds.load('db/schema.cds')).to(
      'sqlite::memory:'
    );
  });
  beforeEach(async () => {
    jest.resetAllMocks();
    for (const entity of [
      'Imports',
      'FindingRecords',
      'DevelopmentObjects',
      'HistoricDevelopmentObjects',
      'DevelopmentObjectFindings',
      'DevelopmentObjectVersions'
    ]) {
      await database.run(cds.ql.DELETE.from(`kernseife.db.${entity}`));
    }
    importId = cds.utils.uuid();
    await database.run(
      cds.ql.INSERT.into('kernseife.db.Imports').entries({
        ID: importId,
        systemId: 'TEST'
      })
    );
  });
  afterAll(async () => {
    await database?.disconnect();
  });

  const importResults = async () => ({
    rows: await database.run(
      cds.ql.SELECT.from('kernseife.db.DevelopmentObjects')
        .columns('objectName', 'languageVersion_code', 'level', 'score')
        .orderBy('objectName')
    ),
    findings: await database.run(
      cds.ql.SELECT.from('kernseife.db.DevelopmentObjectFindings')
    )
  });
  const expectedResults = {
    rows: languages.map((entry) => ({
      objectName: entry.objectName,
      languageVersion_code: entry.languageVersion,
      level: entry.expectedLevel,
      score: 0
    })),
    findings: []
  };

  it('imports CSV language-only objects with Cloud at A/0 and key user at B/0', async () => {
    const csv = papa.unparse(
      findings.map(
        ({
          itemId,
          objectType,
          objectName,
          devClass,
          softwareComponent,
          messageId,
          refObjectType,
          refObjectName
        }) => ({
          itemId,
          objectType,
          objectName,
          devClass,
          softwareComponent,
          messageId,
          refObjectType,
          refObjectName
        })
      )
    );
    await database.tx((tx) =>
      importFindingsCSV(
        {
          ID: importId,
          systemId: 'TEST',
          fileType: 'text/csv',
          file: Readable.from([csv])
        } as Import,
        tx
      )
    );
    expect(await importResults()).toEqual(expectedResults);
  });

  it('imports connector language-only objects with the same classification', async () => {
    jest
      .mocked(connector.getDestinationBySystemId)
      .mockResolvedValue('TEST_DESTINATION');
    jest.mocked(connector.getProject).mockResolvedValue({
      projectId: 'PROJECT',
      runId: 'RUN',
      totalObjectCount: 3
    } as ProjectImport);
    jest.mocked(connector.getFindingsCount).mockResolvedValue(3);
    jest.mocked(connector.getFindings).mockResolvedValue(findings);
    jest.mocked(connector.getDevelopmentObjectsCount).mockResolvedValue(3);
    jest.mocked(connector.getDevelopmentObjects).mockResolvedValue(
      languages.map((entry): DevelopmentObjectImport => ({
        projectId: 'PROJECT',
        runId: 'RUN',
        objectType: 'CLAS',
        objectName: entry.objectName,
        subType: '',
        devClass: 'ZPKG',
        softwareComponent: 'TEST',
        languageVersion: entry.languageVersion,
        contactPerson: '',
        _findings: [],
        _usages: [],
        _metrics: {
          projectId: 'PROJECT',
          objectType: 'CLAS',
          objectName: entry.objectName,
          difficulty: 0,
          numberOfChanges: 0
        }
      }))
    );
    jest.mocked(connector.getExemptionsCount).mockResolvedValue(0);
    await database.tx((tx) => importFindingsBTP(importId, tx));
    expect(await importResults()).toEqual(expectedResults);
  });
});
