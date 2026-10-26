# Running the BTP tests

From the `btp` directory, run `npm ci`, followed by `npm test`. Tests regenerate
the CDS model modules before running, so a fresh checkout has the required
runtime enums and type declarations. Jest ignores generated deployment files
under `gen/` to avoid duplicate package-name errors after a build.

Run `npm run test:typecheck` to check the test and imported service code with
TypeScript. This command also generates the CDS model modules first.
