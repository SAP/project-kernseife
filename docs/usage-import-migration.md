# Usage import snapshot proposal (#82)

The confirmed behavior is one latest usage snapshot per system, with failed imports restarted from the beginning. The selected import system supplies `systemId`; the ABAP payload does not need a new field. Usage keys and parent-object navigation include that system. Counters are source snapshot values, not cumulative totals across imports.

Pages are upserted into an internal staging table scoped by import and system. Only after development objects and exemptions finish does a fresh database transaction delete that system's old usages, insert the staged snapshot and clear the staging rows. An empty successful snapshot removes stale usages for that system. Failures clean up committed staging pages and retain the previous published usage snapshot. Retrying the same import clears its own finding records/version/history artifacts and begins paging at zero; a fresh import ID is also supported.

This does not make the entire import atomic: development objects, findings and exemptions still commit during the import. Different import IDs isolate usage staging, but concurrent jobs for the same system remain outside the verified behavior. The existing `ALL` import path shares one DevelopmentObjectVersions ID across systems; its separate version-key collision is not resolved here. Test sequential system imports separately.

## Required migration decision before merge/deployment

Existing DevelopmentObjectUsages rows have no source system. Adding a column cannot recover their provenance. The maintainer has been asked whether to preserve these rows as unassigned until systems are reimported, or supply a known system ID applying to all existing rows. No migration may discard or attribute them without that answer.

The draft intentionally does not update `db/src/kernseife.db.DevelopmentObjectUsages.hdbmigrationtable` or `db/last-dev/csn.json`. Those artifacts still describe the old key. After the decision, add a reviewed HANA migration that backfills the chosen value, enforces non-null systemId and replaces the primary key; generate the staging-table artifact and update the CDS migration snapshot together. Do not deploy the draft schema against an existing HANA container.

## Validation

SQLite tests deploy the actual CDS schema. They exercise duplicate keys within/across pages, per-system replacement and navigation, discarded staging on restart, empty snapshots, transaction rollback, full import failure after a committed page, restarting the same/fresh import, missing pages, and failure of the later exemptions request. Both server and test TypeScript checks are required. The server check supplies `rootDir: .`, matching the independent proposal in PR #99.

Before marking ready, validate the HANA migration against a populated test container, run import/retry from the Jobs application with real S/4HANA 2025 connector data, and verify that identical usage object keys in two systems remain separate. ABAP activation/runtime testing is performed by the maintainer.
