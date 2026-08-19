#!/usr/bin/env node
/*
 * generate-web-index — the data behind the page in web/.
 *
 * The three sample repositories each publish the answer to the question their
 * corpus is actually asked. abap2UI5/samples publishes a learning path,
 * because "where do I start" is what a newcomer arrives with.
 * abap2UI5/samples-controls publishes a search box over 430 control ports,
 * because "which one shows a Wizard" is what a control reference is asked.
 *
 * This corpus is asked something else again, and neither page answers it:
 *
 *     "my system is on 7.50 and on-premise — what of this can I even run?"
 *     "is there a sample for WebSockets, and what do I have to set up first?"
 *
 * Both are questions about the SYSTEM, not about the sample: everything here
 * needs something beyond an abap2UI5 installation, and which something is the
 * one fact that decides whether a reader can use a sample at all. So the page
 * is a search over the catalogue with two facets — the system you have, and
 * the technology you came for — and every card says what it needs and what it
 * costs before you click anything.
 *
 * There is no playground link, unlike the other two pages. The playground runs
 * a class in a transpiled ABAP in the browser, with no system behind it — and
 * a system is exactly what every sample here requires. A Gateway service, a
 * RAP business object, an APC channel, a launchpad: none of it exists in that
 * frame, so every one of these apps would open and then fail. A link that
 * cannot work is worse than no link, so the cards link into the SOURCE and
 * into the package README that says how to set the sample up.
 *
 * Where every fact comes from — no fact is restated here, all of them are read
 * out of what the repository already keeps:
 *
 *   scripts/lib/scan-samples.mjs   which classes are apps, their title from
 *                                  DESCRIPT, `@summary`, `@keywords` — the
 *                                  same scan behind SAMPLES.md and
 *                                  check-keywords, so the page and the
 *                                  catalogue cannot disagree
 *   .github/packages.json          the package index: directory, branch name,
 *                                  title, the release the package needs
 *   README.md, the package table   what the package plays together with, and
 *                                  the one line describing it. That column is
 *                                  written for a reader and there is nowhere
 *                                  better to keep it; check-overview.mjs
 *                                  already gates that every package has a row
 *                                  carrying the release packages.json declares
 *   the class's ABAP-Doc header    the long description, where a class has one
 *
 *   node scripts/generate-web-index.mjs           write web/apps.json
 *   node scripts/generate-web-index.mjs --check   validate, write nothing
 *   node scripts/generate-web-index.mjs --out X   write it elsewhere
 *
 * NOT committed — web/apps.json is a build output. deploy-web regenerates it on
 * every deploy, so the page can never be staler than the tree it describes and
 * a sample pull request carries no diff of derived data. `--check` is what CI
 * runs (npm run check:web): it holds everything that can go wrong in a pull
 * request — a package with no README row, a row whose cells cannot be read, an
 * app whose package is unknown — without needing the output.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { scanSamples, sampleTitle } from './lib/scan-samples.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const CHECK = process.argv.includes('--check');
const argOut = process.argv.indexOf('--out');
const OUT = argOut === -1
  ? path.join(ROOT, 'web', 'apps.json')
  : path.resolve(process.argv[argOut + 1]);

/* The repository the links point into. The page is built from main, so that is
 * the ref the blob links follow; the branch links point at the generated
 * one-package branches, which is what a reader pulls with abapGit. */
const REPO = 'abap2UI5/samples-stack';
const REF = 'main';
const SOURCE = `https://github.com/${REPO}/blob/${REF}/`;
const TREE = `https://github.com/${REPO}/tree/`;

/* The overview app sits in `src/` itself and is in no package, because it
 * ships on EVERY generated branch (AGENTS.md section 3). It is still an app a
 * reader starts, so it gets a group of its own rather than being dropped from
 * the page.
 *
 * The release is not invented: the branch build lints the overview at its
 * branch's own syntax version, and the lowest of those is v740sp08 — so
 * 7.40 SP08 is measured, exactly like the numbers in packages.json. Cloud
 * likewise: the overview resolves every sample by name at runtime and calls no
 * on-premise API, which is what puts it on the cloud-capable branches. */
const OVERVIEW_PKG = {
  dir: '.',
  branch: REF,
  title: 'Overview',
  topic: 'the catalogue of this repository, inside your system',
  needs: 'nothing beyond abap2UI5 — it ships on every branch and resolves every sample at runtime',
  runsOn: 'Cloud + Standard ≥ 7.40 SP08',
  readme: 'README.md',
};

const die = (message) => {
  console.error(`generate-web-index: ${message}`);
  process.exit(1);
};

/* ------------------------------------------------------------- the packages */

/**
 * The `What is in here` table of the root README, by package directory.
 *
 * | [`src/01`](src/01) | **[OData](…)** — bind a table … | an activated … | Cloud + … |
 *
 * `topic` is the half of the second cell behind the em dash, `needs` the third
 * cell — the "Plays together with" column, which is the answer to "what do I
 * have to have before this sample does anything".
 */
function readmeTable() {
  const rows = fs.readFileSync(path.join(ROOT, 'README.md'), 'utf8')
    .split('\n')
    .filter((line) => line.startsWith('| [`src/'));

  const table = new Map();
  let previous = '';
  for (const line of rows) {
    const cells = line.split('|').slice(1, -1).map((c) => c.trim());
    const dir = (cells[0].match(/src\/(\S+?)`/) || [])[1];
    if (!dir) die(`cannot read the package directory out of README row:\n    ${line}`);

    const topic = (cells[1].split('—')[1] || '').trim();
    if (!topic) die(`the README row for src/${dir} has no "— what it is" half in its Topic cell`);

    /* `as above` is how the table says "the same as the row before" — a
     * sentence for a reader, and nothing a card can show on its own. */
    const needs = /^as above$/i.test(cells[2]) ? previous : cells[2];
    if (!needs) die(`the README row for src/${dir} has an empty "Plays together with" cell`);
    previous = needs;

    table.set(dir, { topic, needs, runsOn: cells[3] });
  }
  return table;
}

/**
 * The release floor of a `runsOn` string, as a number that sorts.
 *
 *   "Cloud + Standard ≥ 7.40 SP08"  ->  740.08, "7.40 SP08"
 *   "Standard only, ≥ 7.54 (1909)"  ->  754,    "7.54 (1909)"
 *
 * SP as hundredths, so 7.40 SP08 sorts below 7.50 and above a bare 7.40 — the
 * order the facet needs, and the only arithmetic on a release number anywhere.
 */
function release(runsOn) {
  const m = runsOn.match(/≥\s*(\d)\.(\d\d)(?:\s*SP(\d+))?/);
  if (!m) die(`cannot read a release out of "${runsOn}" — expected "≥ 7.40 SP08" or "≥ 7.54"`);
  const platform = (runsOn.match(/\((\d{4})\)/) || [])[1] || '';
  return {
    num: Number(`${m[1]}${m[2]}`) + (m[3] ? Number(m[3]) / 100 : 0),
    label: `${m[1]}.${m[2]}${m[3] ? ` SP${m[3]}` : ''}${platform ? ` (${platform})` : ''}`,
  };
}

function packages() {
  const declared = JSON.parse(fs.readFileSync(path.join(ROOT, '.github', 'packages.json'), 'utf8'));
  const table = readmeTable();

  const build = (entry, prose) => {
    const { num, label } = release(entry.runsOn);
    return {
      dir: entry.dir,
      branch: entry.branch,
      title: entry.title,
      topic: prose.topic,
      needs: prose.needs,
      runsOn: entry.runsOn,
      /* "Cloud + Standard ≥ x" vs "Standard only, ≥ x" — the one fact that
       * decides whether a BTP tenant can see the sample at all. */
      cloud: /cloud/i.test(entry.runsOn),
      release: label,
      releaseNum: num,
      note: entry.note || '',
      readme: entry.readme || `src/${entry.dir}/README.md`,
      count: 0,
    };
  };

  const out = [build(OVERVIEW_PKG, OVERVIEW_PKG)];
  for (const entry of declared) {
    const prose = table.get(entry.dir);
    /* check-overview.mjs fails on this too, and from the other side. Repeated
     * here because this generator cannot describe a package it cannot read. */
    if (!prose) die(`src/${entry.dir} is in .github/packages.json but has no row in the README table`);
    if (prose.runsOn !== entry.runsOn) {
      die(`src/${entry.dir}: README says "${prose.runsOn}", packages.json says "${entry.runsOn}"`);
    }
    out.push(build(entry, prose));
  }
  return out;
}

/* ------------------------------------------------------- the long description */

/**
 * The class's ABAP-Doc header, as blocks a page can render.
 *
 * Twelve of the app classes carry one and it is the fullest description this
 * repository has of them — the EML statement, what the sample adds over the one
 * before it, which surprise is worth a comment. Where there is none the card
 * stops at `@summary`, which every app has.
 *
 * The `<p class="shorttext synchronized">` line is dropped: that is the
 * DESCRIPT again, which the card already shows as its title.
 *
 * Blocks are what a blank `"!` line separates, and each one is classified by
 * its FIRST line, because that is the only reading that does not confuse a
 * wrapped bullet with a line of ABAP — both are indented by four:
 *
 *   `- …`      a list. The wrapped lines belong to the item above them.
 *   indented   code (the EML statement). Dedented by the block's own margin,
 *              and it keeps its line breaks — that shape IS the statement.
 *   otherwise  prose, joined into one paragraph: the breaks in the source are
 *              the 80-column margin, not the author's.
 *
 * ABAP Doc is HTML, so the source carries `&lt;no&gt;` where the author wrote
 * `<no>`. Unescaped here, once — the page escapes everything it renders.
 */
function abapDoc(source) {
  const lines = [];
  for (const raw of source.split(/\r?\n/)) {
    if (/^\s*$/.test(raw) || /^"(?!!)/.test(raw)) continue;   // blank, or a plain " comment
    if (!raw.startsWith('"!')) break;                          // the CLASS statement — done
    if (/<p class="shorttext/.test(raw)) continue;
    lines.push(raw.slice(2).replace(/^ /, ''));
  }

  const unescape = (s) => s
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&');

  /* the blank `"!` lines are the paragraph breaks */
  const groups = [];
  for (const line of lines) {
    if (!line.trim()) { groups.push([]); continue; }
    if (!groups.length) groups.push([]);
    groups[groups.length - 1].push(line);
  }

  return groups.filter((g) => g.length).map((group) => {
    if (/^\s*[-*]\s/.test(group[0])) {
      const items = [];
      for (const line of group) {
        if (/^\s*[-*]\s/.test(line)) items.push(line.replace(/^\s*[-*]\s/, ''));
        else if (items.length) items[items.length - 1] += ` ${line.trim()}`;
      }
      return { type: 'list', items: items.map(unescape) };
    }
    if (/^\s{3,}\S/.test(group[0])) {
      const margin = Math.min(...group.map((l) => l.match(/^ */)[0].length));
      return { type: 'code', text: unescape(group.map((l) => l.slice(margin)).join('\n')) };
    }
    return { type: 'p', text: unescape(group.map((l) => l.trim()).join(' ')) };
  });
}

/* -------------------------------------------------------------------- build */

const byDir = new Map(packages().map((p) => [p.dir, p]));
const all = scanSamples(ROOT);
const apps = [];

for (const s of all.filter((x) => x.isApp)) {
  const pkg = byDir.get(s.pkg);
  /* A subpackage — src/03/01 holds the business object, not an app. If an app
   * ever lands in one, the page would silently lose it, so say so instead. */
  if (!pkg) die(`${s.cls} lives in src/${s.pkg}, which is no package of .github/packages.json`);

  const { title, sub } = sampleTitle(s, s.section);
  pkg.count += 1;
  apps.push({
    cls: s.cls.toUpperCase(),
    file: s.rel,
    pkg: s.pkg,
    title,
    sub,
    summary: s.summary,
    keywords: s.keywords ? s.keywords.split(/\s+/) : [],
    doc: abapDoc(fs.readFileSync(path.join(ROOT, s.rel), 'utf8')),
  });
}

const index = {
  repo: REPO,
  source: SOURCE,
  tree: TREE,
  overviewApp: OVERVIEW_PKG.dir,
  packages: [...byDir.values()],
  apps,
};

/* The two ways this page fails without failing: an app with nothing to search
 * for, and a package nobody can be told how to set up. Both are gated
 * elsewhere (check-keywords, check-overview) — checked again here because this
 * generator is what turns them into a page, and a card missing its line is the
 * silent kind of broken. */
const mute = apps.filter((a) => !a.summary || !a.keywords.length).map((a) => a.cls);
if (mute.length) die(`${mute.join(', ')} — no @summary or no @keywords, so nobody searching finds them`);
if (!apps.length) die('no apps found under src/ — the scan came back empty');

if (CHECK) {
  const counts = index.packages.map((p) => `${p.title}: ${p.count}`).join(', ');
  console.log(`check-web: ${apps.length} app(s) in ${index.packages.length} group(s) — ${counts}`);
} else {
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, `${JSON.stringify(index, null, 1)}\n`);
  console.log(`generate-web-index: wrote ${apps.length} app(s) in ${index.packages.length} group(s) to ${path.relative(ROOT, OUT)}`);
}
