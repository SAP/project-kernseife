# Usage import snapshot proposal (#82)

The confirmed behavior is one latest usage snapshot per system, with failed imports restarted from the beginning. The selected import system supplies `systemId`; the ABAP payload does not need a new field. Usage keys and parent-object navigation include that system. Counters are source snapshot values, not cumulative totals across imports.

Pages are upserted into an internal staging table scoped by import and system. Only after development objects and exemptions finish does a fresh database transaction delete that system's old usages, insert the staged snapshot and clear the staging rows. An empty successful snapshot removes stale usages for that system. Failures clean up committed staging pages and retain the previous published usage snapshot. Retrying the same import clears its own finding records/version/history artifacts and begins paging at zero; a fresh import ID is also supported.

This does not make the entire import atomic: development objects, findings and exemptions still commit during the import. Different import IDs isolate usage staging, but concurrent jobs for the same system remain outside the verified behavior. The existing `ALL` import path shares one DevelopmentObjectVersions ID across systems; its separate version-key collision is not resolved here. Test sequential system imports separately.

## Migration of existing rows

The maintainer confirmed that existing DevelopmentObjectUsages rows must be preserved as unassigned. Version 2 of the HANA migration adds systemId as a nullable column, backfills the empty string, then makes the column non-null and includes it in the primary key. No row is deleted or assigned to a configured system. Counter is widened from INTEGER to BIGINT to match the existing CDS Int64 declaration.

Unassigned rows remain stored after any system is reimported, including successful empty snapshots. They do not join to a particular system's development objects. Staging and publication reject an empty system ID, so imports cannot replace the preserved rows. Their provenance is still unknown; any future attribution/removal requires a separate decision.

The current and staging migration tables and `db/last-dev/csn.json` are updated together. Compile/build checks must confirm that another build produces no migration version changes. Validate version 1 to 2 against a populated HANA test container before deployment to an existing landscape: compare row counts, all natural-key fields, counters and timestamps; every pre-existing row must have an empty systemId afterward. Then import one real system and verify that those legacy rows remain alongside the new snapshot. The fresh-install table definition must also deploy successfully.

## Validation

SQLite tests deploy the actual CDS schema. They exercise duplicate keys within/across pages, per-system replacement and navigation, discarded staging on restart, empty snapshots, transaction rollback, full import failure after a committed page, restarting the same/fresh import, missing pages, and failure of the later exemptions request. Both server and test TypeScript checks are required. The server check supplies `rootDir: .`, matching the independent proposal in PR #99.

Runtime validation remains required: validate the HANA migration against a populated test container, run import/retry from the Jobs application with real S/4HANA 2025 connector data, and verify that identical usage object keys in two systems remain separate. ABAP activation/runtime testing is performed by the maintainer.
