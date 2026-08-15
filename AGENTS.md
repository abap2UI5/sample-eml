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
npm run check        # what CI runs: abaplint + abap2UI5-linter + overview
```

Individually: `npm run lint` (abaplint), `npm run check:abap2ui5` (the app
class and the view it builds, including a headless render of every view),
`npm run check:overview` (the four consistency directions between the overview
app, the tree, `packages.json` and the README table).

`npm run fmt:chains` applies the house chain layout. It rewrites whitespace
between chain segments only — but it needs the ABAP to be *balanced* to know
where a statement ends, so run `npm run lint` first if a chain is mid-edit.

## 5. Conventions that are checked here

`abaplint.jsonc` runs the rule set `samples-controls` holds itself to, minus
two that fight RAP rather than finding anything:

- `keyword_case` is **off** — CDS entities, actions and fields are CamelCase by
  definition (`Ticket`, `TravelUuid`, `Activate`), and the rule reads every one
  as a violation.
- `max_one_statement` is **off** — the operator mapping in app 319 is a table
  written as a `CASE`, one `WHEN` per line, and splitting it loses the shape.
- `unused_variables` and `unused_methods` **exclude the `bp_` behavior pools**:
  a handler's parameters are fixed by its signature, the runtime is what calls
  it, and abaplint has no grammar for `RAISE ENTITY EVENT`.

Everything else applies, including `commented_code`, `unused_variables`,
`whitespace_end` and `7bit_ascii`. An EML result clause you do not read
(`MAPPED`/`REPORTED`/`FAILED`) is an unused variable — leave the clause out.

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

## 7. When you add a sample

1. Pick the package by what the sample **needs from the system**. If the answer
   is "nothing but abap2UI5", it belongs in `abap2UI5/samples`.
2. Name it `Z2UI5_CL_SMPS_APP_<no>`, following the numbers already in the
   package.
3. Add it to the overview app's catalogue in `z2ui5_cl_smps_app_00` — by name,
   never with a static reference.
4. Say what it needs in the package README if it needs anything new.
5. `npm run check`.
