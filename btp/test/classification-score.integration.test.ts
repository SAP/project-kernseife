import cds from '@sap/cds';
import type { Service } from '@sap/cds';
import type { Classification } from '#cds-models/kernseife/db';
import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it
} from '@jest/globals';
import { updateTotalScoreAndReferenceCount } from '../srv/features/classification-feature';

describe('classification score aggregation (#97)', () => {
  // CAP exposes these APIs at runtime, but cds-types does not declare them yet.
  type TestDatabase = Service & { disconnect(): Promise<void> };
  const runtime = cds as typeof cds & {
    deploy(model: Awaited<ReturnType<typeof cds.load>>): {
      to(destination: string): Promise<TestDatabase>;
    };
  };
  let database: TestDatabase;

  beforeAll(async () => {
    const model = await cds.load('db/schema.cds');
    database = await runtime.deploy(model).to('sqlite::memory:');
  });

  beforeEach(async () => {
    await database.run(
      cds.ql.DELETE.from('kernseife.db.DevelopmentObjectFindings')
    );
  });

  afterAll(async () => {
    await database?.disconnect();
  });

  const classification = (totalScore = 0, referenceCount = 0) =>
    ({
      objectType: 'TYPE_A',
      objectName: 'REFERENCE_A',
      totalScore,
      referenceCount
    }) as Classification;

  const finding = (
    objectName: string,
    total: number | null,
    count: number | null,
    refObjectType = 'TYPE_A',
    refObjectName = 'REFERENCE_A'
  ) => ({
    version_ID: cds.utils.uuid(),
    objectType: 'IMPLEMENTATION',
    objectName,
    refObjectType,
    refObjectName,
    devClass: 'TEST_PACKAGE',
    code: 'TEST_CODE',
    total,
    count
  });

  it('sums findings for the referenced object type and name', async () => {
    await database.run(
      cds.ql.INSERT.into('kernseife.db.DevelopmentObjectFindings').entries([
        finding('IMPLEMENTATION_1', 20, 2),
        finding('IMPLEMENTATION_2', 15, 3),
        finding('OTHER_TYPE', 990, 99, 'TYPE_B'),
        finding('OTHER_NAME', 880, 88, 'TYPE_A', 'REFERENCE_B')
      ])
    );
    const value = classification();

    expect(await updateTotalScoreAndReferenceCount(value)).toBe(true);
    expect(value.totalScore).toBe(35);
    expect(value.referenceCount).toBe(5);
    expect(await updateTotalScoreAndReferenceCount(value)).toBe(false);
  });

  it('resets stale totals when there are no matching findings', async () => {
    await database.run(
      cds.ql.INSERT.into('kernseife.db.DevelopmentObjectFindings').entries([
        finding('UNRELATED', 40, 4, 'TYPE_B')
      ])
    );
    const value = classification(35, 5);

    expect(await updateTotalScoreAndReferenceCount(value)).toBe(true);
    expect(value.totalScore).toBe(0);
    expect(value.referenceCount).toBe(0);
  });

  it('treats null aggregate values as zero', async () => {
    await database.run(
      cds.ql.INSERT.into('kernseife.db.DevelopmentObjectFindings').entries([
        finding('EMPTY_TOTALS', null, null)
      ])
    );
    const value = classification(35, 5);

    expect(await updateTotalScoreAndReferenceCount(value)).toBe(true);
    expect(value.totalScore).toBe(0);
    expect(value.referenceCount).toBe(0);
  });
});
