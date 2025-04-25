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