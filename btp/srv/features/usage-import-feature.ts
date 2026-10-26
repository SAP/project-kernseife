import type { DevelopmentObjectUsage } from '#cds-models/kernseife/db';
import { ql, Transaction } from '@sap/cds';

const CURRENT = 'kernseife.db.DevelopmentObjectUsages';
const STAGING = 'kernseife.db.DevelopmentObjectUsageImports';

const requireSystemId = (systemId: string) => {
  if (!systemId) {
    throw new Error(
      'Usage imports require a system ID; unassigned legacy rows cannot be replaced'
    );
  }
};
const columns = [
  'systemId',
  'entryPointObjectType',
  'entryPointObjectName',
  'objectType',
  'objectName',
  'counter',
  'lastUsed'
];

export const clearUsageImport = async (
  tx: Transaction,
  importId: string,
  systemId: string
) => {
  requireSystemId(systemId);
  await tx.run(
    ql.DELETE.from(STAGING).where({ import_ID: importId, systemId })
  );
};

export const stageUsageImport = async (
  tx: Transaction,
  importId: string,
  systemId: string,
  usages: Partial<DevelopmentObjectUsage>[]
) => {
  requireSystemId(systemId);
  if (usages.length === 0) return;

  // A usage can appear under more than one development object/page. Keep the
  // latest source values rather than adding counters or inserting duplicates.
  const entries = new Map<string, Partial<DevelopmentObjectUsage>>();
  for (const usage of usages) {
    const key = JSON.stringify([
      usage.entryPointObjectType,
      usage.entryPointObjectName,
      usage.objectType,
      usage.objectName
    ]);
    entries.set(key, usage);
  }
  await tx.run(
    ql.UPSERT.into(STAGING).entries(
      [...entries.values()].map((usage) => ({
        ...usage,
        systemId,
        import_ID: importId
      }))
    )
  );
};

// The caller must commit these statements together, with no intermediate
// progress updates/commits, so readers see either the old or the new snapshot.
export const publishUsageImport = async (
  tx: Transaction,
  importId: string,
  systemId: string
) => {
  requireSystemId(systemId);
  await tx.run(ql.DELETE.from(CURRENT).where({ systemId }));
  await tx.run(
    ql.INSERT.into(CURRENT).from(
      ql.SELECT.from(STAGING)
        .columns(...columns)
        .where({ import_ID: importId, systemId })
    )
  );
  await clearUsageImport(tx, importId, systemId);
};
