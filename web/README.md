# `web/` — the page on GitHub Pages

**<https://abap2ui5.github.io/samples-stack/>** — every sample of this
repository, searchable by the technology it plays with and by the release your
system actually runs. Published by the
[`deploy-web`](../.github/workflows/deploy-web.yaml) workflow, which needs
*Settings → Pages → Source = GitHub Actions*.

```
web/index.html   the page — one file, no framework
web/stack.css    one stylesheet, light and dark off one set of custom properties
web/stack.js     filtering and drawing — plain ES2020, no dependencies
web/apps.json    generated, NOT committed (see below)
```

## What it answers

It is the fourth view of the same catalogue, and the four are generated from
one scan (`scripts/lib/scan-samples.mjs`) so they cannot disagree:

| Where | For whom |
|---|---|
| `Z2UI5_CL_SMPS_APP_000`, the overview app | somebody who has this repository in a system |
| [`SAMPLES.md`](../SAMPLES.md) | somebody reading the repository on GitHub |
| the package READMEs | somebody who has already picked a technology |
| this page | somebody who has installed nothing and is asking whether their system can run any of it |

That last question is what makes this page different from the two next door.
[samples](https://abap2ui5.github.io/samples/) publishes a learning path,
because *"where do I start"* is what a newcomer arrives with;
[samples-controls](https://abap2ui5.github.io/samples-controls/) publishes a
search over 430 control ports, because *"which one shows a Wizard"* is what a
control reference is asked. Here everything needs something **from the system**,
so the two questions are:

> *"my system is 7.50 and on-premise — what of this can I even run?"*
> *"is there a sample for WebSockets, and what do I have to set up first?"*

Both are answered by facts the repository already keeps. `.github/packages.json`
declares each package's release and the branch it ships on; the README's package
table says what it plays together with; the classes carry `@summary`,
`@keywords` and — twelve of them — an ABAP-Doc header, which is the fullest
description this repository has of a sample and goes on the card behind *What
the class documents*.

The **Your system** facet is one select for both halves of the release
question: ABAP Cloud drops the three on-premise packages, a Standard release
keeps every package at or below it. The counts are in the labels, so what an
older system costs is visible before the click. Filters live in the URL, so a
search is linkable.

## There is no playground link

The other two pages open a class in the
[playground](https://abap2ui5.github.io/playground/) — the ABAP in an editor
with the app running beside it, no system anywhere. That is exactly what cannot
work here: a Gateway service, a RAP business object, an APC channel, a launchpad
is what every sample in this repository needs, and none of it exists in that
frame. Every app would open and then fail.

So the cards link where a link can help: **Source** (one class, the whole
sample), **Setup** (the package README's *What you need* section) and **Branch**
(the generated one-package branch, which is what you give abapGit if you only
want this package on your system).

## `apps.json` is not committed

It is derived from the tree, so committing it would put a diff of derived data
on every sample pull request while adding a gate that can only restate what the
generator already says. `deploy-web` regenerates it on every deploy instead, so
it is never staler than the site serving it.

```bash
npm run web:index      # node scripts/generate-web-index.mjs
npm run check:web      # what CI runs: validate, write nothing
```

`npm run check:web` is part of `npm run check` and has its own workflow. It
holds what a pull request can break without touching this folder: a package
with no README row, a row whose cells no longer parse, an app in a directory
that is no package of `.github/packages.json`.

## Running it locally

Nothing to build:

```bash
npm run web:index
python3 -m http.server 8099 --directory web    # any static server will do
```

`file://` does not work — the page `fetch`es `apps.json`. Every outgoing link is
absolute (GitHub), so they work from a local server exactly as in production.
