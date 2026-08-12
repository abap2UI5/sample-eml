#!/usr/bin/env node
// Keeps the overview app and the repository in sync.
//
// z2ui5_cl_smpe_app_00 references every sample BY NAME and resolves it at
// runtime, so that it survives a package the system cannot activate and a
// checkout that carries only part of this repository (see the class
// documentation). The price is that the compiler no longer notices a renamed
// or a newly added sample - this check is what notices instead.
//
// Two directions:
//   1. every sample class in the tree is listed in the overview  (always)
//   2. every class the overview names exists in the tree         (full tree only)
//
// (2) is skipped when a package directory is missing: a checkout with a
// single package is a supported case, and there the overview lists classes
// that are legitimately absent - at runtime they simply show up as "not on
// this system".

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, basename } from 'node:path';

const SRC = 'src';
const OVERVIEW = join(SRC, 'z2ui5_cl_smpe_app_00.clas.abap');
const PACKAGES = ['01', '02', '03', '04', '05', '06', '07', '08', '09'];

const walk = (dir) =>
  readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });

const files = walk(SRC);

// a sample is an ABAP class implementing z2ui5_if_app - which leaves out
// z2ui5_cl_smpe_app_489_ws, the APC handler behind sample 489, and the
// overview itself
const samples = files
  .filter((path) => /^z2ui5_cl_smpe_app_.*\.clas\.abap$/.test(basename(path)))
  .filter((path) => basename(path) !== basename(OVERVIEW))
  .filter((path) => /INTERFACES\s+z2ui5_if_app\s*\./i.test(readFileSync(path, 'utf8')))
  .map((path) => basename(path).replace('.clas.abap', '').toUpperCase());

// every Z2UI5_CL_SMPE_* class name the overview carries as a string literal:
// the samples in model_init and the two demo data classes in cs_class
const overview = readFileSync(OVERVIEW, 'utf8');
const listed = [...overview.matchAll(/`(Z2UI5_C[LX]_SMPE_[A-Z0-9_]+)`/g)].map((match) => match[1]);

const known = new Set(
  files
    .filter((path) => path.endsWith('.clas.abap'))
    .map((path) => basename(path).replace('.clas.abap', '').toUpperCase()),
);

const complete = PACKAGES.every((pkg) => files.some((path) => path.startsWith(join(SRC, pkg))));

const errors = [];

for (const name of samples) {
  if (!listed.includes(name)) {
    errors.push(`${name} is a sample of this repository but is not listed in ${OVERVIEW}`);
  }
}

for (const name of new Set(listed)) {
  if (complete && !known.has(name)) {
    errors.push(`${OVERVIEW} names ${name}, but no such class exists - renamed or mistyped?`);
  }
}

if (errors.length > 0) {
  console.error('check-overview failed:\n');
  for (const error of errors) console.error(`  - ${error}`);
  console.error(`\n${samples.length} sample(s) in the tree, ${new Set(listed).size} class(es) listed.`);
  process.exit(1);
}

console.log(
  `check-overview: ${samples.length} sample(s) listed in the overview` +
    (complete ? ', every referenced class exists' : ', partial checkout - existence not checked'),
);
