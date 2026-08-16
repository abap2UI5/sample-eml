/*
 * scan-samples — the one place that knows what a sample in this repository is.
 *
 * Two things read this: `check-keywords.mjs`, which insists every app says what
 * it is about, and `generate-samples-md.mjs`, which writes the catalogue. They
 * have to agree on which classes are apps, where a title comes from and which
 * section a sample belongs to — abap2UI5/samples learned that the hard way and
 * says so in its AGENTS.md: two copies of this drift silently, and then the
 * catalogue and the gate simply disagree about what the repository contains
 * while both keep passing.
 *
 * The rules, and why they are these:
 *
 *   an APP implements z2ui5_if_app. Everything else — behavior pools, demo
 *   data, event consumers, the generated APC protocol class — is a helper,
 *   reached BY a sample rather than looked up, and is exempt from everything
 *   here. Decided from the source rather than from a list somebody maintains,
 *   because a list would need maintaining and would rot.
 *
 *   the SECTION is the CTEXT of the package the class physically lives in,
 *   read from its package.devc.xml. Not a table in a script: the package is
 *   where the author already made that decision.
 *
 *   the TITLE is the class's DESCRIPT, split on the first ` - ` into a header
 *   and a sub, exactly as abap2UI5/samples splits it. A header that only
 *   repeats its section heading is dropped by the generator — the section
 *   already said it.
 */
import fs from 'fs';
import path from 'path';

const unescapeXml = (s) => s
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"').replace(/&apos;/g, "'")
  .replace(/&amp;/g, '&');

const tag = (xml, name) => {
  const m = xml.match(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`));
  return m ? unescapeXml(m[1]) : '';
};

/** The class DESCRIPT, split the way abap2UI5/samples splits it. */
export function splitDescript(d) {
  const t = d.trim();
  const i = t.indexOf(' - ');
  return i === -1 ? { header: t, sub: '' } : { header: t.slice(0, i), sub: t.slice(i + 3) };
}

function walk(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    if (fs.statSync(full).isDirectory()) walk(full, out);
    else if (full.endsWith('.clas.abap')) out.push(full);
  }
  return out;
}

/** The CTEXT of a package folder, cached — several classes share one. */
function packageText(dir, cache = new Map()) {
  if (cache.has(dir)) return cache.get(dir);
  const devc = path.join(dir, 'package.devc.xml');
  const text = fs.existsSync(devc) ? tag(fs.readFileSync(devc, 'utf8'), 'CTEXT') : '';
  cache.set(dir, text);
  return text;
}

/**
 * Every class under src/, in package order, apps and helpers alike.
 *
 * @returns {{cls: string, file: string, rel: string, isApp: boolean,
 *            descript: string, header: string, sub: string,
 *            keywords: string, section: string, pkg: string}[]}
 */
export function scanSamples(root) {
  const SRC = path.join(root, 'src');
  const cache = new Map();
  const out = [];

  for (const file of walk(SRC)) {
    const cls = path.basename(file, '.clas.abap');
    const source = fs.readFileSync(file, 'utf8');
    const xmlPath = file.replace(/\.clas\.abap$/, '.clas.xml');
    const descript = fs.existsSync(xmlPath)
      ? tag(fs.readFileSync(xmlPath, 'utf8'), 'DESCRIPT')
      : '';

    const dir = path.dirname(file);
    const { header, sub } = splitDescript(descript || cls);

    out.push({
      cls,
      file,
      rel: path.relative(root, file).replace(/\\/g, '/'),
      isApp: /INTERFACES\s+z2ui5_if_app\s*\./i.test(source),
      descript,
      header,
      sub,
      keywords: (source.match(/^" @keywords (.+?)\r?$/m) || [, ''])[1].trim(),
      section: packageText(dir, cache),
      // `src/` for the overview app, `01`, `03/01`, … for everything else, so
      // a nested subpackage sorts directly after its parent
      pkg: path.relative(SRC, dir).replace(/\\/g, '/') || '.',
    });
  }

  return out.sort((a, b) => a.pkg.localeCompare(b.pkg) || a.cls.localeCompare(b.cls));
}

/*
 * The overview app's own catalogue — and the reason the page is generated from
 * it rather than from the class DESCRIPT.
 *
 * Both exist, and they disagree. For app 315 the DESCRIPT reads
 * "Model - Use OData models"; the overview app says "Two OData models in one
 * view", with "one table bound to each, column headers from the metadata"
 * under it. The second is the curated text — it is what somebody actually sees
 * when they run the overview — and the first is an abapGit short text, capped
 * at 60 characters and written for ADT's object list.
 *
 * Rendering the page from DESCRIPT would have produced a THIRD description of
 * every sample, disagreeing with the app that this page claims to be a reading
 * copy of. So the app's catalogue is the source: one place, already curated,
 * already checked by check-overview.mjs for naming a class that exists. This
 * function reads it back out, and generate-samples-md.mjs closes the loop the
 * other way — every app in the tree has to appear in it.
 *
 * Parsed with a regex over ABAP source, which is only tolerable because the
 * shape is regular and machine-written-looking, and because a miss is loud:
 * an entry that stops matching fails the completeness check rather than
 * quietly dropping a row.
 */
const ENTRY = /sample\(\s*no\s*=\s*`([^`]*)`[\s\S]*?title\s*=\s*`([^`]*)`[\s\S]*?detail\s*=\s*`([^`]*)`[\s\S]*?classname\s*=\s*`([^`]*)`/g;

export function scanOverview(root, overviewClass = 'z2ui5_cl_smps_app_00') {
  const file = path.join(root, 'src', `${overviewClass}.clas.abap`);
  const text = fs.readFileSync(file, 'utf8');
  const byClass = new Map();
  for (const m of text.matchAll(ENTRY)) {
    byClass.set(m[4].toLowerCase(), { no: m[1], title: m[2], detail: m[3] });
  }
  return byClass;
}
