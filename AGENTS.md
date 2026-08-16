# AGENTS.md — abap2UI5/samples-stack

The guide for this repository. Read it before changing anything under `src/`.

This file is deliberately short. The ABAP style, the view-builder chain layout
and the app conventions are **shared with `abap2UI5/samples`** and documented
there once — [`samples/AGENTS.md`](https://github.com/abap2UI5/samples/blob/main/AGENTS.md),
sections 7 (naming and style) and 11 (app structure). What follows is only what
is different or true here alone.

## 1. What this repository is, and is not

The third step of the learning ladder: `samples` (fundamentals) →
`samples-controls` (the UI5 control set) → **`samples-stack`** (abap2UI5
together with the rest of your stack).

The line is not a topic, it is a requirement: **everything here needs something
from the system beyond an abap2UI5 installation** — a Gateway service, a RAP
business object, an APC channel, an ICF node, SAPUI5's `sap.ui.comp`. That is
what keeps `samples` install-and-run and ABAP-Cloud-clean, and it is why a
sample that runs standalone belongs there, not here.

Two consequences worth stating:

- **No 7.02 downport.** EML sets the floor at 1909, so this repository is not
  downported the way the others are. `abaplint.jsonc` checks `main` at v757.
- **Objects other than classes.** Packages bring their own tables, data
  elements, CDS entities, behavior definitions and service bindings. They are
  part of the sample, not scaffolding around it.

## 2. The package scheme

One directory per technology under `src/`, `src/00` for what several of them
share, and the overview app `z2ui5_cl_smps_app_00` in the root.

`.github/packages.json` is the index: directory, branch name, title, the
release the package needs, its abaplint syntax version, and the `shared`
directories it takes with it. Adding a package means adding an entry there —
the branch build, the abaplint version and the README table all read it.

Naming, enforced by `object_naming`:

```
Z2UI5_CL_SMPS_<object>   classes, including behavior pools   (max 25 chars)
Z2UI5_T_SMPS_<object>    persistent tables                   (max 16 chars)
Z2UI5_D_SMPS_<object>    draft tables                        (max 16 chars)
Z2UI5_R_SMPS_<object>    CDS root view entities + behavior definitions
```

The 25-character cap is not ABAP's 30: `build_rename` swaps the 5-character
`z2ui5` namespace for one up to 9 long, which costs 4. Tables are capped at 16
because that is the DDIC limit — a 17-character table does not activate.

## 3. The generated one-package branches

abapGit imports a whole repository; there is no sparse checkout. Nine packages
with different floors would mean a system that wants OData also takes APC and
gets activation errors for technology it never asked for. So every package is
force-pushed to its own branch by `create-package-branches.yaml`, and the
abapGit branch dropdown becomes the place you pick your feature.

What that costs you when you edit:

- **Work on `main`.** A generated branch is rebuilt and force-pushed on every
  push to `main`; anything committed there is gone at the next build.
- **The overview app ships on every branch** and lists every sample of the
  repository, marking the ones this checkout does not carry as unavailable. So
  it must not reference anything a branch might not have. It references samples
  BY NAME and resolves them at runtime for exactly that reason — and it carries
  its own url helper rather than calling one, because `src/00` travels only
  with the two packages that name it in `shared`. `check:overview` fails on a
  static `Z2UI5_CL_SMPS_*` reference that would not survive every branch.
- Each branch is linted at **its own** release before it is pushed, which is
  what makes the "Runs on" column in the README true rather than aspirational.

## 4. Build & verify

```sh
npm ci
npm run check        # abaplint + abap2UI5-linter + overview + keywords + SAMPLES.md
```

Individually: `npm run lint` (abaplint), `npm run check:abap2ui5` (the app
class and the view it builds, including a headless render of every view),
`npm run check:overview` (the four consistency directions between the overview
app, the tree, `packages.json` and the README table).

`npm run fmt:chains` applies the house chain layout. It rewrites whitespace
between chain segments only — but it needs the ABAP to be *balanced* to know
where a statement ends, so run `npm run lint` first if a chain is mid-edit.

## 5. Conventions that are checked here

**The rule block in `abaplint.jsonc` is byte-identical in three
repositories** — this one, [samples](https://github.com/abap2UI5/samples) and
[samples-controls](https://github.com/abap2UI5/samples-controls) — the same way
`scripts/chain-format.mjs` is shared between the other two. abaplint has no
`extends`, so the copy is the mechanism, and the block carries a header saying
so. **Change it here and copy it to the other two**, then re-run their gates:
what is checked is a joint decision of the three corpora, not a local
preference.

Only `global`, `dependencies` and `syntax` are per repository (this one runs
at `v757` against the full steampunk API, and silences the RAP event handler
abaplint cannot parse) — plus exactly **one** rule: `object_naming`, which
carries the `SMPS` token. It sits last in the file behind a marker that says
so; everything above that marker must stay identical.

All 188 rules abaplint ships are named: 171 on, 17 off, each with its reason
in a comment. **A rule is never left out of the file** — when an upgrade adds
one, add the key in all three: on if all three corpora pass, off with the
reason if they do not.

RAP is what makes this corpus different from the other two, and the shared
block carries **scoped excludes** for it rather than turning rules off for
everybody. Each pattern matches nothing under the other two `src/` trees:

- `keyword_case` excludes `z2ui5_cl_smps_*` — CDS entities, actions and fields
  are CamelCase by definition (`Ticket`, `TravelUuid`, `Activate`), and the
  rule reads every one as a violation (31 findings, all correct ABAP).
- `unused_variables` / `unused_methods` exclude the `bp_` behavior pools: a
  handler's parameters are fixed by its signature, the runtime is what calls
  it, and abaplint has no grammar for `RAISE ENTITY EVENT`.
- `local_class_naming` excludes them too — `lhc_<entity>` is the name RAP
  mandates. `check_abstract` likewise: a behavior pool is `ABSTRACT FINAL` by
  definition.
- `select_single_full_key` excludes them: their `SELECT SINGLE` is an
  aggregate (`MAX( travel_id )`), which returns exactly one row by definition.
- `unused_ddic` excludes the persistent and draft tables — they are referenced
  from the CDS and behavior definitions, which abaplint does not trace into.
- `fully_type_constants` excludes apps 07 and 10: `TYPE RESPONSE FOR FAILED /
  REPORTED EARLY` is fully typed RAP syntax abaplint reads as implicit.
- `max_one_statement` excludes app 319 — its operator mapping is a table
  written as a `CASE`, one `WHEN` per line, and splitting it loses the shape.
- `check_syntax` / `superclass_final` exclude app 489: ABAP Push Channels are
  on-premise only and absent from the steampunk dependency.
- `cds_naming` takes the `Z2UI5_` namespace instead of SAP's per-category
  `ZI_` / `ZC_` / `ZR_` prefixes — the root view entities here are
  `Z2UI5_R_SMPS_<object>`.
- `smim_consistency` is off outright: the two `.mp3` SMIM objects in `08/01`
  have a parent MIME folder that lives on the system, not in the repository.

Everything else applies, including `commented_code`, `unused_variables`,
`whitespace_end` and `7bit_ascii`. An EML result clause you do not read
(`MAPPED`/`REPORTED`/`FAILED`) is an unused variable — leave the clause out.
Local type names follow `^TY_` like the other two repositories (`ty_s_` for a
structure, `ty_t_` for its table) — the looser `t_` this repository used is
gone.

> **Write a configured rule's flags out in full.** abaplint replaces the whole
> options object, so a partial one silently turns every flag it omits *off* —
> `"check_subrc": { "selectTable": false }` disables the rule entirely instead
> of narrowing it.

## 6. Documentation that travels with a sample

- Every package has a `README.md` with a **What you need** paragraph: release,
  branch, and the setup step (create the service binding, activate the ICF
  node, publish the OData service). A reader must not have to guess.
- Every app class carries an ABAP-Doc header (`"!`) saying what it demonstrates
  and what it needs. `src/03` and `src/04` are the reference for how much: the
  EML statement in the header, and comments where `%cid`, rollback semantics or
  "validations run at COMMIT" would otherwise surprise a reader.
- The class description in `.clas.xml` (`<DESCRIPT>`) is what the overview app
  shows. Keep it in Title Case and specific.
- **Every app carries a `" @keywords` line as the first line of its
  `.clas.abap`** — checked by `npm run check:keywords`:

  ```abap
  " @keywords stateful session lock navigation nav_app_call check_on_navigated
  CLASS z2ui5_cl_smps_app_490 DEFINITION PUBLIC.
  ```

  A plain `"` comment and not `"!`, because an unknown `"! @tag` is reported by
  the extended check (SLIN/ATC). Lowercase, space separated, four to eight
  terms. The convention is [abap2UI5/samples](https://github.com/abap2UI5/samples)'
  (its AGENTS.md §4), unchanged on purpose so one reader can read both
  repositories.

  Put in what a newcomer would **type** and the class name cannot hold:
  synonyms (`flp` for launchpad, `eml` for the RAP entity API), the controls
  the sample actually builds (`smartfilterbar`, `feedlistitem`) and the
  abap2UI5 API it demonstrates (`set_session_stateful`, `nav_app_call`). Leave
  out the scaffolding — `check_on_init`, `view_display` and `_bind` are in all
  32 apps and therefore separate none of them.

  Why it is gated: nothing about a missing line is broken. The app compiles,
  runs, and appears in the overview. The only symptom is that nobody looking
  for it arrives — the overview's search box, `Ctrl+F` over a catalogue, and an
  agent asking "is there already a sample for WebSockets" all come up empty in
  the same silent way. This repository ran that way for its whole life.

  A class that does **not** implement `z2ui5_if_app` is a helper — a behavior
  pool, demo data, an event consumer, the generated APC protocol class — and is
  exempt, because a helper is reached *by* a sample rather than looked up. That
  is decided from the source, not from a list somebody has to maintain.

  `" @docs` (the link back to a documentation chapter) is **not** added here by
  hand: the pairing is declared on the documentation side, in the page's
  `samples:` frontmatter, and generated back.
- **[`SAMPLES.md`](SAMPLES.md) is the catalogue as a page** — generated by
  `npm run samples:md`, checked by `npm run check:samples-md`, **not** edited by
  hand. The overview app answers "what is in here" once abap2UI5, a service
  binding and the packages are on a system; before that it answers nothing, and
  this page does.

  **Its source is the overview app's own catalogue**, not the class `DESCRIPT`.
  Both exist and they disagree — app 315's DESCRIPT reads *"Model - Use OData
  models"* while the overview says *"Two OData models in one view"* with *"one
  table bound to each, column headers from the metadata"* under it. The second
  is the curated text, the first is a 60-character abapGit short text written
  for ADT's object list. Rendering the page from DESCRIPT would have produced a
  **third** description of every sample, disagreeing with the app this page
  claims to be a reading copy of.

  So: title and detail come from `z2ui5_cl_smps_app_00`, the search terms from
  the class's `@keywords`, the link from the file path. One place per fact.

  Two checks close the loop in both directions. `check-overview` refuses a
  catalogue entry naming a class that does not exist; `check:samples-md`
  refuses an app that exists and is in no entry — the case that leaves a
  working sample invisible in the app *and* on the page.

  **The row format is byte-for-byte abap2UI5/samples'**, on purpose: `ai-mcp`'s
  `examples` tool and `docs`' `link-samples.mjs` already parse those rows with a
  regex. Neither reads this repository yet, and the identical shape is what
  makes that a configuration change over there rather than a second parser.
  Changing the shape is not a cosmetic decision — a row that stops matching is
  a row that silently is not there.

## 7. When you add a sample

1. Pick the package by what the sample **needs from the system**. If the answer
   is "nothing but abap2UI5", it belongs in `abap2UI5/samples`.
2. Name it `Z2UI5_CL_SMPS_APP_<no>`, following the numbers already in the
   package.
3. Add it to the overview app's catalogue in `z2ui5_cl_smps_app_00` — by name,
   never with a static reference.
4. Give it a `" @keywords` line as its first line (§6) — what somebody would
   type who does not know your sample exists.
5. Say what it needs in the package README if it needs anything new.
6. `npm run samples:md` and commit `SAMPLES.md` with it (§6).
7. `npm run check`.
