[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__smpe-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![abap-standard](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-standard.yaml)
[![abap-cloud](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-cloud.yaml/badge.svg)](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-cloud.yaml)
[![check-abap2UI5](https://github.com/abap2UI5/samples-ext/actions/workflows/check-abap2UI5.yaml/badge.svg)](https://github.com/abap2UI5/samples-ext/actions/workflows/check-abap2UI5.yaml)

# abap2UI5 — samples-ext

**abap2UI5 in company with other technologies.**

abap2UI5 is more than a standalone framework for building apps. At its core it is
deliberately agnostic: it makes no assumption about where your data comes from,
which model backs your UI, or which stack you have already invested in. That
neutrality is what makes it flexible — whenever it is useful, abap2UI5 plugs into
what your system already offers.

This repository shows exactly that. OData, Smart Controls, RAP with and without
draft, RAP business events, stateful sessions and ABAP locks, WebSockets via
AMC/APC, the MIME repository — abap2UI5 works alongside each of them, and each one
keeps doing what it is good at. Nothing here replaces an existing technology;
everything here complements one. Whether you use any of it is entirely up to you —
*everything is possible, nothing is required*.

The samples live in their own repository simply because they reach beyond a plain
abap2UI5 installation: they use something the system provides, so the basic
samples in [abap2UI5/samples](https://github.com/abap2UI5/samples) stay
install-and-run.

Every area is self-contained and brings its own README. Pick the one you came for
and try it out — the others can wait until you need them.

## What is in here

| Package | Topic | Plays together with |
|---|---|---|
| [`src/01`](src/01) | **[OData](src/01/README.md)** — bind a table to an OData V2 model | an activated OData V2 service |
| [`src/02`](src/02) | **[Smart Controls](src/02/README.md)** — `sap.ui.comp` driven by OData metadata | SAPUI5 + an activated Gateway service |
| [`src/03`](src/03) | **[RAP](src/03/README.md)** — consume a business object with EML | ABAP Platform >= 1909; the BO ships with this repo |
| [`src/04`](src/04) | **[RAP with Draft](src/04/README.md)** — the same, draft enabled | as above |
| [`src/05`](src/05) | **[Business Events](src/05/README.md)** — react to RAP events, log them, show them | as above |
| [`src/06`](src/06) | **[Stateful Sessions / Locks](src/06/README.md)** — sticky session, `ENQUEUE` | ABAP Standard (on-premise), the table `Z2UI5_T_SMPE_01` |
| [`src/07`](src/07) | **[AMC/APC](src/07/README.md)** — a news feed over WebSocket | on-premise APC/AMC, the ICF node `Z2UI5_APC_SMP_2` |
| [`src/08`](src/08) | **[MIME Play Audio](src/08/README.md)** — play a sound from the MIME repository | the ICF service `/SAP/PUBLIC/BC/ABAP/mime_demo` |

The numbering is a reading order, not a dependency chain: `01` starts where most
systems already are — an activated OData service — and each package from there
reaches a little deeper into the stack. Enter wherever your system is today.

## Setup

1. Install [abap2UI5](https://github.com/abap2UI5/abap2UI5).
2. Pull this repository with [abapGit](https://abapgit.org). It runs on ABAP
   Platform >= 1909 or a BTP ABAP Environment — that is what EML asks for, which
   is why it is the one sample repository without a 7.02 downport.
3. Set up whatever the package you picked builds on — its README says so in one
   short section.
4. Start an app with `?app_start=<class name>`.

Every sample of the abap2UI5 sample scheme is called `Z2UI5_CL_SMPE_APP_<no>`, and
the tables in the package READMEs give you the number, so sample `487` is
`?app_start=z2ui5_cl_smpe_app_487`. The RAP packages additionally come with an
overview app that lists and launches their samples:
`?app_start=z2ui5_cl_smpe_app_00`.

## Structure

```
src/                 z2ui5_cl_smpe_app_00 - the overview app of the RAP samples
src/00/00            context shared by the RAP samples
src/01               OData                    sample 315
src/02               Smart Controls           samples 313, 314, 319, 475-479
src/03               RAP, no draft            samples 01-05
src/03/01            the business object      Z2UI5_R_SMPE_TRV, Z2UI5_T_SMPE_TRV
src/04               RAP with draft           samples 06-10
src/04/01            the business object      Z2UI5_R_SMPE_TRD, Z2UI5_T_SMPE_TRD, Z2UI5_D_SMPE_TRD
src/05               Business Events          the ticket BO, its event handler and two apps
src/06               Stateful Sessions/Locks  samples 485, 486, 490
src/06/01            the lock table           Z2UI5_T_SMPE_01
src/07               AMC/APC                  sample 489
src/07/01            channel, push channel, ICF node
src/08               MIME Play Audio          sample 487
src/08/01            the two MIME objects
```

## Namespace

Every object carries the token **`SMPE`** behind its type token — the scheme the
samples repository uses with its `SMP` token:

```
Z2UI5_CL_SMPE_<object>    classes, including the behavior pools
Z2UI5_T_SMPE_<object>     persistent tables
Z2UI5_D_SMPE_<object>     draft tables
Z2UI5_R_SMPE_<object>     CDS root view entities and their behavior definitions
```

Class names are capped at **25** characters, tables at **16**. Both limits and the
patterns themselves are enforced by the `object_naming` rule in
[`abaplint.jsonc`](abaplint.jsonc); the comment there explains where the numbers come
from. `DDLS` and `BDEF` have no `object_naming` key in abaplint, so for those two the
scheme is convention only.

Two groups sit outside the scheme:

- The objects abaplint cannot name-check at all — the AMC channel, the APC push
  channel with its ICF node, and the two MIME objects. They carry the older `SMP`
  token (`Z2UI5_AMC_SMP_2`, `Z2UI5_APC_SMP_2`, `z2ui5_smp_error.mp3`,
  `z2ui5_smp_success.mp3`).
- The **Business Events** package (`src/05`) arrived as a contribution with its own
  `LK22` token and has not been renamed to the scheme yet — abaplint reports each
  of its objects under `object_naming`. The sample itself is complete and runnable;
  the rename is an open point, not a defect.

## Checks

| Workflow | What it does |
|---|---|
| `abap-standard` | `abaplint ./abaplint.jsonc` — syntax `v757`, the on-premise release |
| `abap-cloud` | `abaplint .github/abaplint/abap_cloud.jsonc` — the ABAP Cloud language version |
| `check-abap2UI5` | [`abap2ui5lint`](https://github.com/abap2UI5/linter) — the app class and the view it produces, together |

There is no `abap-702` counterpart and no derived branch: EML runs from ABAP
Platform 1909 onwards, so unlike the other sample repositories this one needs no
downport.

Three things to know when you read the badges:

- abaplint parses EML but does not resolve behavior definitions, so entity, alias and
  action names inside EML statements are not checked, and neither are the
  `.asbdef` files — the samples themselves are the reference here.
- `RAISE ENTITY EVENT` and `FOR ENTITY EVENT` (`src/05`) are beyond the abaplint
  parser as well, so that package reports parser errors on syntax that activates
  fine in an ABAP system.
- `abap-cloud` lints the whole tree, including the areas that are on-premise by
  design (`src/06` `ENQUEUE`, `src/07` APC/AMC). It reports those as errors, which
  is expected: a red cloud badge says those two areas are on-premise, not that the
  RAP samples are broken.

## Where to go from here

Take whichever package matches the technology you already run — an OData service,
a Gateway service, a RAP business object, an APC channel — and put an abap2UI5 app
in front of it. None of these packages depends on another, and none of them is a
prerequisite for using abap2UI5 at all: they are options you can reach for when
they help.

Something else you would like to see combined with abap2UI5? Open an issue or a
pull request — the collection grows with the scenarios people bring to it.
