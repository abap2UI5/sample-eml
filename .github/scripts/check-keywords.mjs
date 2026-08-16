#!/usr/bin/env node
/*
 * check-keywords — every sample app says what it is about.
 *
 * Two lines, both plain `"` comments above the CLASS statement: `@keywords`
 * (what somebody would type) and `@summary` (one sentence, the line a catalogue
 * puts under the title).
 *
 * A sample nobody can find is a sample nobody has. This repository had 40
 * classes and not one `" @keywords` line, so an app here was reachable by its
 * class name and by nothing else: not by the search box of an overview, not by
 * Ctrl+F over a catalogue, and not by an agent asking "is there already a
 * sample for WebSockets". The apps were correct, listed, and invisible.
 *
 * The convention is abap2UI5/samples' (its AGENTS.md section 4), deliberately
 * unchanged so one reader can read both repositories: a plain `"` comment as
 * the FIRST line of the .clas.abap, lowercase, space separated.
 *
 *     " @keywords stateful session lock navigation nav_app_call check_on_navigated
 *     CLASS z2ui5_cl_smps_app_490 DEFINITION PUBLIC.
 *
 * A plain `"` and not `"!` on purpose: an unknown `"! @tag` is reported by the
 * extended check (SLIN/ATC).
 *
 * What belongs in it is what a newcomer would TYPE and the class name cannot
 * hold - synonyms (`flp` for launchpad, `eml` for the RAP entity API), the
 * controls the sample actually builds (`smartfilterbar`, `feedlistitem`), and
 * the abap2UI5 API it demonstrates (`set_session_stateful`, `nav_app_call`).
 * Not the scaffolding every app has: `check_on_init`, `view_display` and
 * `_bind` appear in all 32 of them and therefore separate none of them.
 *
 * WHO NEEDS A LINE is decided from the source, not from a list kept by hand:
 * a class that implements `z2ui5_if_app` is an app and needs one; a class that
 * does not is a helper - a behavior pool, demo data, an event consumer, the
 * generated APC protocol class - and is reached BY a sample rather than looked
 * up. An exemption list would need maintaining and would rot; this cannot.
 *
 *   node .github/scripts/check-keywords.mjs   (npm run check:keywords)
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const SRC = path.join(ROOT, 'src');

/* Loose enough to survive formatting, strict enough to mean it: the line has
 * to be FIRST - a keyword line further down is one a reader scrolls past and
 * one a scanner reading the head of the file would miss. */
const LINE = /^" @keywords (.+)$/;
const MIN_TERMS = 3;

function walk(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    if (fs.statSync(full).isDirectory()) walk(full, out);
    else if (full.endsWith('.clas.abap')) out.push(full);
  }
  return out;
}

const problems = [];
let apps = 0;
let helpers = 0;
const terms = new Set();

for (const file of walk(SRC)) {
  const rel = path.relative(ROOT, file);
  const text = fs.readFileSync(file, 'utf8');
  const isApp = /INTERFACES\s+z2ui5_if_app\s*\./i.test(text);

  if (!isApp) {
    helpers += 1;
    /* A helper does not need one - but if it grew into an app, it does. The
     * check below is what notices that, so a keyword line on a helper is not
     * an error, only unnecessary. */
    continue;
  }
  apps += 1;

  const first = text.split('\n')[0];
  const m = LINE.exec(first);
  if (!m) {
    const later = text.split('\n').findIndex((l) => LINE.test(l));
    problems.push(
      later > 0
        ? `${rel}: the \`" @keywords\` line is on line ${later + 1}, not the first line`
        : `${rel}: implements z2ui5_if_app and has no \`" @keywords\` line\n`
          + '    add one as the FIRST line: synonyms, the controls it builds, the API it shows',
    );
    continue;
  }

  /* @summary is the line a catalogue puts under the title. It exists because
   * DESCRIPT is capped at 60 characters and the useful sentence is usually
   * longer — of the 31 curated descriptions this repository already had, only
   * 13 fit in 60 and the longest was 114. Without it a catalogue row is a
   * title and nothing else. */
  if (!/^" @summary \S/m.test(text)) {
    problems.push(`${rel}: no \`" @summary\` line — one sentence saying what the sample shows`);
  }

  const words = m[1].trim().split(/\s+/);
  if (words.length < MIN_TERMS) {
    problems.push(`${rel}: only ${words.length} keyword(s) — ${MIN_TERMS} is the floor, four to eight is the point`);
  }
  for (const w of words) {
    if (w !== w.toLowerCase()) problems.push(`${rel}: \`${w}\` is not lowercase`);
    if (w.includes('`')) problems.push(`${rel}: \`${w}\` contains a backtick`);
    terms.add(w);
  }
}

console.log(
  `check-keywords: ${apps} app(s), ${helpers} helper(s) exempt; `
  + `${terms.size} distinct search terms`,
);

if (problems.length) {
  console.error(`\n${problems.length} problem(s):`);
  for (const p of problems) console.error(`  ${p}`);
  console.error('\nSee AGENTS.md — a sample nobody can find is a sample nobody has.');
  process.exit(1);
}
console.log('every sample app says what it is about - OK');
