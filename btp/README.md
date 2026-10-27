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

### 3. Install global packages (e.g. CAP's cds-dk and TypeScript)

```sh
npm i -g @sap/cds-dk typescript ts-node
```

## Dependency security maintenance

Use Node.js 22 for local development, matching the deployment workflow. Install
dependencies with `npm ci` in this directory; the HANA deployer has its own
lockfile in `db/`. Audit both with `npm audit` and `npm audit --prefix db`.

The root package overrides Lodash to a patched 4.x release and the UI5 Project
Pacote dependency to 21.5.1 with Sigstore 4.1.1. These address vulnerabilities
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

## Project checks

The `Project checks` GitHub workflow runs for pull requests and pushes to main. It installs dependencies from the lockfile, generates models through the test scripts, runs Jest, type-checks tests and application code, and lints without applying fixes. It builds the production bundle, verifies that all four custom CAP handlers are discovered and initialized, then builds the UI5 workspaces.

The workflow reads Node from `.nvmrc`, pins npm to the validated version 12.0.2, and prefers the lockfile-installed CAP toolkit. Until the toolkit is added to the project lockfile, it uses the pinned version 10.0.7 that was validated with CAP 9. The bundled-handler check installs the generated server's production dependencies and uses that bundle's CAP service factory for regression coverage of #96/#99; it does not require a database, destination credentials or a Cloud Foundry deployment.

To run that check locally after a production build:

```sh
node scripts/checkServiceHandlers.cjs
```
