 Getting Started

Welcome to `Kernseife`.

It contains these folders and files, following our recommended project layout:

| File or Folder | Purpose                              |
| -------------- | ------------------------------------ |
| `app/`         | content for UI frontends goes here   |
| `db/`          | your domain models and data go here  |
| `srv/`         | your service models and code go here |
| `package.json` | project metadata and configuration   |
| `readme.md`    | this getting started guide           |

## Local development setup

### 1. VSCode setup

Download and install [VSCode](https://code.visualstudio.com)

Following VSCode extensions are recommended to be installed:

- [SAP CDS Language Support](https://marketplace.visualstudio.com/items?itemName=SAPSE.vscode-cds)
- [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)
- [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
- [SQLite Viewer](https://marketplace.visualstudio.com/items?itemName=qwtel.sqlite-viewer)
- [Rainbow CSV](https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv)
- [Swagger Viewer](https://marketplace.visualstudio.com/items?itemName=Arjun.swagger-viewer)

### 2. Node Version Manager

Make sure you have installed `nvm` (for installation guide see [here](https://github.com/nvm-sh/nvm#installing-and-updating))
If you run the project for the first time run `nvm install` to install the required Node version otherwise you can run `nvm use` to use the appropriate installed version.

### 3. Install project dependencies

```sh
npm ci
npm ci --prefix db
```

## Dependency security maintenance

Use Node.js 24.18.0 (`nvm use`) for local development, matching the deployment workflow. Install
dependencies with `npm ci` in this directory; the HANA deployer has its own
lockfile in `db/`. Audit both with `npm audit` and `npm audit --prefix db`.

The root package overrides Lodash to a patched 4.x release and the UI5 Project
Pacote dependency to 22.0.1 with Sigstore 5.0.0. These address vulnerabilities
in the versions pinned by upstream build tooling. Keep the overrides until
upstream versions include those fixes, and validate all UI5 builds when changing
them. The unused UI5 JSDoc lint plugin was removed because it installed legacy
ESLint and vulnerable dependencies; linting uses the root `eslint.config.mjs`.

As of 26 October 2026, `node-forge` 1.4.0 remains affected by
[GHSA-86w9-cpqp-85rv](https://github.com/advisories/GHSA-86w9-cpqp-85rv),
with no published patched version. It is pulled in by the Cloud SDK `jks-js`
dependency. Track the upstream fix and review destinations using JKS
certificates before rollout. An audit may consequently still report this
advisory and its dependent packages.

CAP development toolkit 10.2.0 also bundles body-parser 2.3.0, affected by
[GHSA-27r3-jxmh-p828](https://github.com/advisories/GHSA-27r3-jxmh-p828).
Although body-parser 2.4.0 is patched, npm overrides do not replace dependencies
inside the toolkit's published bundle. This development-only dependency awaits
a corrected toolkit release; the production server uses body-parser 2.4.0.

## Dependency upgrade compatibility (26 October 2026)

All direct npm dependencies in the root, nine UI5 workspaces, and HANA deployer
are pinned to their latest stable releases checked on this date, except
TypeScript. TypeScript 6.0.3 is the latest supported by both ts-jest 29.4.15
(`typescript <7`) and typescript-eslint 8.72.0 (`typescript <6.1`); their peer
requirements prevent adopting TypeScript 7.0.2 yet. Transitive packages follow
the versions supported by their parent packages.

The update moves CAP to 10.2.1, HANA/SQLite adapters to 3.1.2, Express to 5.3.0,
Jest to 30.5.2, ESLint to 10.13.0, and UI5 runtime to 1.153.0. The CAP toolkit
is a local, pinned dependency, and deployment installs the lockfile with
`npm ci`. GitHub Actions and the Cloud Foundry CLI are updated as well.
Type generation and CAP type definitions are development dependencies, keeping
their optional toolkit peer out of the production server. Supported transitive
releases are refreshed and deduplicated, so CAP also uses Express 5.3.0.

CAP 10 requires Node 22 or newer. Its compiler maps the existing `Int64` usage
counter to HANA `BIGINT`; the checked-in migration widens the existing `INTEGER`
column. Validate this migration on the deployed HANA database. CAP 10 also
serializes Decimal/Int64 database values as strings by default; check usage
counts, percentage displays, and import/export flows during application testing.

The deployment TypeScript configuration sets `rootDir` explicitly so compiled
handlers stay under `gen/srv/srv`, and removes the deprecated `baseUrl` option.
ESLint 10 findings are fixed by removing unused initial assignments and retaining
the cause of wrapped ZIP errors. The integration fixture supplies local types
for deployment/disconnect APIs omitted by cds-types 0.20.0.

Validation: clean Node 24 installs of both lockfiles; dependency tree without
peer conflicts; application and test TypeScript checks; lint with zero errors;
the complete MTA build, including all nine UI5 ZIPs and production installs;
and a local smoke check of compiled server startup, all four OData metadata
endpoints and collection reads, security/cache headers, and custom favicon handling. The smoke check
uses SQLite and public release-state data, not deployed HANA/BTP connections.

Jest passes 28 of 30 tests. The two failures also occur with the unchanged
dependency versions: they incorrectly require CSV `runId`, which is optional.
Their correction is tracked separately in
[PR #122](https://github.com/SAP/project-kernseife/pull/122). The HANA deployer
audit is clean; the application audit has the two upstream advisories described
above, reported through six affected packages (four in the production server).
