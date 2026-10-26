import type { csn, DatabaseService } from '@sap/cds';

// @cap-js/cds-types 0.18 omits these runtime database APIs. Keep the
// declarations scoped to tests that deploy and close an in-memory database.
declare module '@sap/cds' {
  function deploy(model: csn.CSN): {
    to(connection: string): Promise<DatabaseService>;
  };
  interface DatabaseService {
    disconnect(): Promise<void>;
  }
}
