[![abap version](https://img.shields.io/badge/abap%20version-standard%20%28%E2%89%A5%201909%29-blue)](#setup)
[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__smps-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![abap-standard](https://github.com/abap2UI5/samples-stack/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5/samples-stack/actions/workflows/abap-standard.yaml)
[![check-abap2UI5](https://github.com/abap2UI5/samples-stack/actions/workflows/check-abap2UI5.yaml/badge.svg)](https://github.com/abap2UI5/samples-stack/actions/workflows/check-abap2UI5.yaml)

# abap2UI5 — samples-stack

**Learn how abap2UI5 plays with your stack — OData, RAP, Smart Controls,
WebSockets, the Fiori Launchpad and more.**

abap2UI5 is more than a standalone framework for building apps. At its core it
is deliberately agnostic: it makes no assumption about where your data comes
from, which model backs your UI, or which stack you have already invested in.
That neutrality is what makes it flexible — whenever it is useful, abap2UI5
plugs into what your system already offers.

This repository shows exactly that. OData, Smart Controls, RAP with and without
draft, RAP business events, stateful sessions and ABAP locks, WebSockets via
AMC/APC, the MIME repository, the Fiori Launchpad — abap2UI5 works alongside
each of them, and each one keeps doing what it is good at. Nothing here
replaces an existing technology; everything here complements one. Whether you
use any of it is entirely up to you — *everything is possible, nothing is
required*.

The samples live in their own repository simply because they reach beyond a
plain abap2UI5 installation: they use something the system provides, so the
basic samples in [abap2UI5/samples](https://github.com/abap2UI5/samples) stay
install-and-run.

Every area is self-contained and brings its own README. Pick the one you came
for and try it out — the others can wait until you need them.

## What is in here

| Package | Topic | Plays together with | Runs on |
|---|---|---|---|
| [`src/01`](src/01) | **[OData](src/01/README.md)** — bind a table to an OData V2 model | an activated OData V2 service | Cloud + Standard ≥ 7.40 SP08 |
| [`src/02`](src/02) | **[Smart Controls](src/02/README.md)** — `sap.ui.comp` driven by OData metadata | SAPUI5 + an activated Gateway service | Cloud + Standard ≥ 7.40 SP08 |
| [`src/03`](src/03) | **[RAP](src/03/README.md)** — consume a business object with EML | ABAP Platform >= 1909; the BO ships with this repo | Cloud + Standard ≥ 7.54 (1909) |
| [`src/04`](src/04) | **[RAP with Draft](src/04/README.md)** — use draft handling | as above | Cloud + Standard ≥ 7.54 (1909) |
| [`src/05`](src/05) | **[Business Events](src/05/README.md)** — react to RAP events, log them, show them | as above | Cloud + Standard ≥ 7.56 (2021) |
| [`src/06`](src/06) | **[Stateful Sessions / Locks](src/06/README.md)** — sticky session, `ENQUEUE` | ABAP Standard (on-premise), the table `Z2UI5_T_SMPS_01` | Standard only, ≥ 7.40 SP08 |
| [`src/07`](src/07) | **[AMC/APC](src/07/README.md)** — a news feed over WebSocket | on-premise APC/AMC, the ICF node `Z2UI5_APC_SMP_2` | Standard only, ≥ 7.50 |
| [`src/08`](src/08) | **[MIME Play Audio](src/08/README.md)** — play a sound from the MIME repository | the ICF service `/SAP/PUBLIC/BC/ABAP/mime_demo` | Standard only, ≥ 7.50 |
| [`src/09`](src/09) | **[Launchpad](src/09/README.md)** — startup parameters, shell title, cross-app navigation | a Fiori Launchpad with a tile pointing at abap2UI5 | Cloud + Standard ≥ 7.40 SP08 |

The numbering is a reading order, not a dependency chain: `01` starts where
most systems already are — an activated OData service — and each package from
there reaches a little deeper into the stack. Enter wherever your system is
today.

## The learning path

This repository is step 3 of 3 — the place to connect abap2UI5 with the
technologies you already run. If you are new to abap2UI5, start one step
earlier:

|      | Repository | What you learn | Where to start |
|------|------------|----------------|----------------|
| 1️⃣ | [**samples**](https://github.com/abap2UI5/samples) | **the abap2UI5 basics** — bindings, events, popups, navigation, complete apps | run `Z2UI5_CL_SMP_APP_000` |
| 2️⃣ | [**samples-controls**](https://github.com/abap2UI5/samples-controls) | **how to use every UI5 control** — the UI5 Demo Kit rebuilt with abap2UI5 | run `z2ui5_cl_dmo_app_overview` |
| 3️⃣ | **samples-stack** — 📍 *you are here* | **how abap2UI5 plays with your stack** — OData, RAP, WebSockets, the Fiori Launchpad and more | pick your technology in the table above |

### Reading the *Runs on* column

**Cloud** is the ABAP Cloud stack — a BTP ABAP Environment or an on-stack cloud
development tenant. Three packages cannot go there, and it is the technology, not
the sample, that keeps them out: `06` locks through the function modules
`ENQUEUE_E_TABLE` / `ENQUEUE_READ` and holds a stateful ICF session, `07` needs
on-premise APC/AMC, `08` reads the MIME repository over an ICF path. None of those
is a released ABAP Cloud API.

**Standard** is the on-premise release, given as the `SAP_BASIS` version with the
ABAP Platform name where there is one — `7.54` is 1909, `7.56` is 2021. The number
is the higher of two floors:

- *the ABAP the package is written in.* Unlike the other sample repositories this
  one is not downported to 7.02, so **7.40 SP08 is the floor everywhere**. These
  syntax floors are measured, not estimated: one abaplint run per release over the
  tree, and the number in the table is the lowest release the package parses clean
  at.
- *the technology the package plays with.* EML lifts `03` and `04` to 1909, RAP
  business events lift `05` to 2021. If `RAISE ENTITY EVENT` does not activate on
  your system, `05` is out of reach and nothing else in this repository is
  affected.

The repository **as a whole** therefore asks for 1909, because `03`–`05` do. A
single package can ask for much less — which matters if you are only here for one
of them.

## Setup

1. Install [abap2UI5](https://github.com/abap2UI5/abap2UI5).
2. Pull this repository with [abapGit](https://abapgit.org) — `main` for all nine
   packages, or the branch of the single package you came for (see
   [One package at a time](#one-package-at-a-time)). `main` as a whole runs on
   ABAP Platform >= 1909 or a BTP ABAP Environment — that is what EML asks for,
   which is why it is the one sample repository without a 7.02 downport.
3. Set up whatever the package you picked builds on — its README says so in one
   short section.
4. Start an app with `?app_start=<class name>`.

Every sample of the abap2UI5 sample scheme is called `Z2UI5_CL_SMPS_APP_<no>`, and
the tables in the package READMEs give you the number, so sample `487` is
`?app_start=z2ui5_cl_smps_app_487`.

### Pulling over an older checkout

The packages were renumbered once, so a system that pulled this repository before
that has objects sitting in packages the folders no longer point at. abapGit moves
most of them on the next pull, but a MIME object keeps the package it was created
in, and you get a warning naming the package it came from:

```
SMIM 027C66AAA6591EDFA9BB6B42F39E45DD exists but package $..._07_01 is missing
(might have been lost during an upgrade, SAP Note 2478895)
```

Both of them belong to `08` now, the two sounds sample `487` plays. The quickest
way out is to delete them and let abapGit put them back where the tree says they
go: SE80 → MIME Repository → `SAP/PUBLIC/BC/ABAP/mime_demo`, delete
`z2ui5_smp_error.mp3` and `z2ui5_smp_success.mp3`, then pull again. If the warning
names other objects too, pull the `DEVC` entries alone first — that recreates
every package of the current layout — and pull the rest afterwards.

## The overview app

You do not have to look a number up. `?app_start=z2ui5_cl_smps_app_00` lists
**every sample of this repository**, one collapsible section per package, and
starts each one in a new browser tab — so the overview stays where it is and
several samples can run side by side. Its header button fills the demo data of
both RAP packages.

It is also the honest answer to *what does my system actually support*: the
overview looks every sample up at runtime instead of referencing it statically, so
a package your release cannot activate — or one you never installed — is listed
with its Open button disabled and a Status saying so, rather than taking the whole
overview down. Start it first, and the list tells you which of the nine packages
this system can run.

## One package at a time

abapGit imports a **whole repository** — there is no way to pull half of one. On
`main` that means a system that came for `01` also gets the three on-premise
packages and the three that need 1909, and reports activation errors for
technology it never asked for.

So every package additionally lives on **its own branch**. Each branch carries the
number of the package it holds, so the abapGit branch dropdown lists them in the
same reading order as the table above. Pick one and you import that package, the
overview app and nothing else:

| Branch | Package | Runs on |
|---|---|---|
| [`01-odata`](../../tree/01-odata) | [`src/01`](src/01) — OData | Cloud + Standard ≥ 7.40 SP08 |
| [`02-smart-controls`](../../tree/02-smart-controls) | [`src/02`](src/02) — Smart Controls | Cloud + Standard ≥ 7.40 SP08 |
| [`03-rap`](../../tree/03-rap) | [`src/03`](src/03) — RAP | Cloud + Standard ≥ 7.54 (1909) |
| [`04-rap-draft`](../../tree/04-rap-draft) | [`src/04`](src/04) — RAP with Draft | Cloud + Standard ≥ 7.54 (1909) |
| [`05-business-events`](../../tree/05-business-events) | [`src/05`](src/05) — Business Events | Cloud + Standard ≥ 7.56 (2021) |
| [`06-stateful-locks`](../../tree/06-stateful-locks) | [`src/06`](src/06) — Stateful Sessions / Locks | Standard only, ≥ 7.40 SP08 |
| [`07-amc-apc`](../../tree/07-amc-apc) | [`src/07`](src/07) — AMC/APC | Standard only, ≥ 7.50 |
| [`08-mime`](../../tree/08-mime) | [`src/08`](src/08) — MIME Play Audio | Standard only, ≥ 7.50 |
| [`09-launchpad`](../../tree/09-launchpad) | [`src/09`](src/09) — Launchpad | Cloud + Standard ≥ 7.40 SP08 |

The overview app ships on every branch and keeps listing **all 31 samples**, so it
stays the catalogue of what the other branches hold — the ones that are not on
your branch simply show up with a disabled Open button.

These branches are **generated**: `create-package-branches` rebuilds and
force-pushes every one of them on every push to `main`, and abaplint checks each
one at the release that package declares before it is pushed. Work on `main` —
issues and pull requests against a generated branch go nowhere, and a commit
pushed to one is gone at the next build.

## Namespace

Every object carries the token **`SMPS`** behind its type token — the scheme the
samples repository uses with its `SMP` token:

```
Z2UI5_CL_SMPS_<object>    classes, including the behavior pools and event handlers
Z2UI5_T_SMPS_<object>     persistent tables
Z2UI5_D_SMPS_<object>     draft tables
Z2UI5_E_SMPS_<object>     data elements
Z2UI5_R_SMPS_<object>     CDS entities and their behavior definitions
Z2UI5_SD_SMPS_<object>    service definitions
Z2UI5_SB_SMPS_<object>    service bindings
```

Runnable samples are `Z2UI5_CL_SMPS_APP_<no>`, so the class name is what you pass to
`?app_start=`.

Class names are capped at **25** characters, tables at **16**. Both limits and the
patterns themselves are enforced by the `object_naming` rule in
[`abaplint.jsonc`](abaplint.jsonc); the comment there explains where the numbers come
from. The other object types have no `object_naming` key in abaplint, so for those
the scheme is convention only.

One group sits outside the scheme: the objects abaplint cannot name-check at all —
the AMC channel, the APC push channel with its ICF node, and the two MIME objects.
They carry the older `SMP` token (`Z2UI5_AMC_SMP_2`, `Z2UI5_APC_SMP_2`,
`z2ui5_smp_error.mp3`, `z2ui5_smp_success.mp3`).

## Checks

| Workflow | What it does |
|---|---|
| `abap-standard` | `abaplint ./abaplint.jsonc` — syntax `v757`, the on-premise release |
| `check-abap2UI5` | [`abap2ui5lint`](https://github.com/abap2UI5/linter) — the app class and the view it produces, together |
| `check-overview` | the two hand-kept indexes: every sample is listed in the overview app, and the package table matches `.github/packages.json` |
| `create-package-branches` | rebuilds the nine per-package branches, each verified with abaplint at its own release before it is pushed |

`check-overview` exists because the overview app names its samples as strings and
resolves them at runtime — that is what lets it survive a package the system cannot
activate, and it is also what stops the compiler from noticing a renamed or a newly
added sample. The check notices instead, and it compares the *Runs on* column with
the releases [`.github/packages.json`](.github/packages.json) declares, which is
where the generated branches take theirs from. It runs `node
.github/scripts/check-overview.mjs`, needs no dependencies, and skips both
full-tree halves on a checkout that carries only part of the repository.

`create-package-branches` runs on pull requests too, everything except the push —
so a change that would break one of the branches fails while it can still be
fixed. Adding a package is one entry in `.github/packages.json`; neither the
workflow nor the checks have to be touched.

There is no `abap-702` counterpart: EML runs from ABAP Platform 1909 onwards, so
unlike the other sample repositories this one needs no downport — the derived
branches here split the tree by package, they do not downport it. There is no
`abap-cloud` counterpart either — several packages here are
on-premise by design (`src/06` `ENQUEUE`, `src/07` APC/AMC), so a cloud syntax check
over the whole tree would report expected errors rather than useful ones.

Two things to know when you read the badges:

- abaplint parses EML but does not resolve behavior definitions, so entity, alias and
  action names inside EML statements are not checked, and neither are the
  `.asbdef` files — the samples themselves are the reference here.
- `RAISE ENTITY EVENT` and `FOR ENTITY EVENT` (`src/05`) are beyond the abaplint
  parser as well, so that package reports parser errors on syntax that activates
  fine in an ABAP system.

## Where to go from here

Take whichever package matches the technology you already run — an OData service,
a Gateway service, a RAP business object, an APC channel — and put an abap2UI5 app
in front of it. None of these packages depends on another, and none of them is a
prerequisite for using abap2UI5 at all: they are options you can reach for when
they help.

Something else you would like to see combined with abap2UI5? Open an issue or a
pull request — the collection grows with the scenarios people bring to it.
