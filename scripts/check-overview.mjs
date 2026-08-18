#!/usr/bin/env node
// Keeps the overview app and the repository in sync.
//
// z2ui5_cl_smps_app_000 references every sample BY NAME and resolves it at
// runtime, so that it survives a package the system cannot activate and a
// checkout that carries only part of this repository (see the class
// documentation). The price is that the compiler no longer notices a renamed
// or a newly added sample - this check is what notices instead.
//
// Four directions:
//   1. every sample class in the tree is listed in the overview  (always)
//   2. every class the overview names exists in the tree         (full tree only)
//   3. every package of .github/packages.json is in the README
//      table with the release it declares                        (full tree only)
//   4. every class the overview references STATICALLY survives on
//      every generated package branch                            (full tree only)
//
// (3) is the second index this repository keeps by hand: packages.json drives
// the generated per-package branches and the release each one is checked at,
// the README table tells the reader the same thing in prose. They drift apart
// silently, so they are compared here.
//
// (4) is the rule the class documentation states and nothing enforced: the
// overview ships on every branch, but a branch carries only its own package
// plus whatever it names in "shared", so a static reference into any other
// package leaves that branch with an overview that does not activate. It
// happened - z2ui5_cl_smps_context=>app_get_url( ) took seven of the nine
// branches down for a day, and the nine-job branch matrix was the first thing
// to say so. This check says it in a second, before the matrix ever starts.
//
// (2), (3) and (4) are skipped when a package directory is missing: a checkout
// with a single package is a supported case - it is what the generated branches
// are - and there the overview lists classes that are legitimately absent. At
// runtime they simply show up as "not on this system".

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, basename } from 'node:path';

const SRC = 'src';
const OVERVIEW = join(SRC, 'z2ui5_cl_smps_app_000.clas.abap');
const packages = JSON.parse(readFileSync(join('.github', 'packages.json'), 'utf8'));
const PACKAGES = packages.map((entry) => entry.dir);

const walk = (dir) =>
  readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });

const files = walk(SRC);

// a sample is an ABAP class implementing z2ui5_if_app - which leaves out
// z2ui5_cl_smps_app_489_ws, the APC handler behind sample 489, and the
// overview itself
const samples = files
  .filter((path) => /^z2ui5_cl_smps_app_.*\.clas\.abap$/.test(basename(path)))
  .filter((path) => basename(path) !== basename(OVERVIEW))
  .filter((path) => /INTERFACES\s+z2ui5_if_app\s*\./i.test(readFileSync(path, 'utf8')))
  .map((path) => basename(path).replace('.clas.abap', '').toUpperCase());

// every Z2UI5_CL_SMPS_* class name the overview carries as a string literal:
// the samples in model_init and the two demo data classes in cs_class
const overview = readFileSync(OVERVIEW, 'utf8');
const listed = [...overview.matchAll(/`(Z2UI5_C[LX]_SMPS_[A-Z0-9_]+)`/g)].map((match) => match[1]);

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

if (complete) {
  // the overview with its comments and its string literals taken out. What is
  // left is ABAP the compiler resolves, so a Z2UI5_CL_SMPS_* name in there is
  // a STATIC reference - the by-name lookups all sit inside backticks and are
  // gone by now. Template literals keep their embedded { ... } expressions,
  // which are code as well; only their literal text is dropped.
  const code = overview
    .replace(/`[^`\n]*`/g, '``')
    .replace(/'[^'\n]*'/g, "''")
    .replace(/\|[^|{}\n]*\|/g, '||')
    .split('\n')
    .map((line) => (line.trimStart().startsWith('*') ? '' : line.replace(/".*$/, '')))
    .join('\n');

  // where each class of the tree lives, as the top level entry under src/ that
  // build-package-branch.mjs keeps or deletes as a whole
  const home = new Map(
    files
      .filter((path) => path.endsWith('.clas.abap'))
      .map((path) => [
        basename(path).replace('.clas.abap', '').toLowerCase(),
        path.split(/[\\/]/)[1],
      ]),
  );

  // what every branch keeps out of src/ on top of its own package - the same
  // list build-package-branch.mjs applies, and the reason the overview itself
  // is not reported here
  const always = /^(package\.devc\.xml|z2ui5_cl_smps_app_000\.clas\..*)$/;

  for (const name of new Set([...code.matchAll(/z2ui5_c[lx]_smps_[a-z0-9_]+/g)].map((m) => m[0]))) {
    const dir = home.get(name);
    if (dir === undefined || always.test(dir)) continue;

    const orphans = packages
      .filter((entry) => entry.dir !== dir && !entry.shared.includes(dir))
      .map((entry) => entry.branch);

    if (orphans.length > 0) {
      errors.push(
        `${OVERVIEW} references ${name.toUpperCase()} statically, but src/${dir} is not on ` +
          `${orphans.length} of the ${packages.length} generated branches (${orphans.join(', ')}) - ` +
          `use the framework instead, or add "${dir}" to their "shared" in .github/packages.json`,
      );
    }
  }

  const rows = readFileSync('README.md', 'utf8')
    .split('\n')
    .filter((line) => line.startsWith('| [`src/'));

  for (const entry of packages) {
    const row = rows.find((line) => line.startsWith(`| [\`src/${entry.dir}\`]`));
    if (!row) {
      errors.push(`README.md has no table row for src/${entry.dir}`);
    } else if (!row.includes(entry.runsOn)) {
      errors.push(
        `README.md row for src/${entry.dir} does not carry the release ` +
          `.github/packages.json declares ("${entry.runsOn}")`,
      );
    }
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
