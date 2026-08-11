[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__smpe-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![abap-standard](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-standard.yaml)
[![abap-cloud](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-cloud.yaml/badge.svg)](https://github.com/abap2UI5/samples-ext/actions/workflows/abap-cloud.yaml)
[![check-abap2UI5](https://github.com/abap2UI5/samples-ext/actions/workflows/check-abap2UI5.yaml/badge.svg)](https://github.com/abap2UI5/samples-ext/actions/workflows/check-abap2UI5.yaml)

# abap2UI5 — samples-ext

The samples that need **more than a standalone abap2UI5 installation**.

Everything in [abap2UI5/samples](https://github.com/abap2UI5/samples) runs on a
plain stack: install abap2UI5, pull the repository, start an app. The demos
collected here do not — each one needs something the system has to provide
first: a RAP business object, an activated OData service, an ICF node, a stateful
session, a MIME object. That is the only thing they have in common, and it is why
they live in their own repository instead of cluttering the basic samples with
prerequisites.

Every area is self-contained. Pick the one you came for; you do not have to set
up the others.

## What is in here

| Package | Topic | Needs |
|---|---|---|
| [`src/01`](src/01) | **RAP** — consume a business object with EML | ABAP Platform >= 1909, the two BOs ship with this repo |
| [`src/02`](src/02) | **RAP with Draft** — the same, draft enabled | as above |
| [`src/03`](src/03) | **Smart Controls** — `sap.ui.comp` against OData V2 | SAPUI5 (not OpenUI5) + an activated Gateway service |
| [`src/04`](src/04) | **OData** — bind a table to an OData V2 model | an activated OData V2 service |
| [`src/05`](src/05) | **Stateful Sessions / Locks** — sticky session, `ENQUEUE` | ABAP Standard (on-premise), the table `Z2UI5_T_SMPE_01` |
| [`src/06`](src/06) | **AMC/APC** — a news feed over WebSocket | on-premise APC/AMC, the ICF node `Z2UI5_APC_SMP_2` |
| [`src/07`](src/07) | **MIME Play Audio** — play a sound from the MIME repository | the ICF service `/SAP/PUBLIC/BC/ABAP/mime_demo` |

## Setup

1. Install [abap2UI5](https://github.com/abap2UI5/abap2UI5).
2. Pull this repository with [abapGit](https://abapgit.org). Unlike the other
   sample repositories this one is **not downported to 7.02** — EML needs
   ABAP Platform >= 1909 or a BTP ABAP Environment.
3. Do whatever the area you want asks for (see its section below).
4. Start an app with `?app_start=<class name>`.

The RAP samples have an overview app that lists and launches them:
`?app_start=z2ui5_cl_smpe_app_00`. The other areas have none — start those samples
by class name. Every sample is called `Z2UI5_CL_SMPE_APP_<no>`, and the tables
below give you the number, so sample `487` is
`?app_start=z2ui5_cl_smpe_app_487`.

---

# RAP — consume a business object with EML

`src/01` (without draft) and `src/02` (draft enabled).

No OData service, no annotations, the view is built in plain ABAP. One runnable
sample per statement, plus the two business objects to run them against, so
nothing else has to be installed.

**Two ways in:**

- **You know EML and want the snippet** → [Find the snippet](#find-the-snippet). Every class carries its statement in the comment at the very top, so you see it the moment you open the file.
- **RAP is new to you** → read [The business object](#the-business-object) first. It is one page, and without it half the messages the samples show will not mean anything.

## Start here

Run [`00 overview`](src/z2ui5_cl_smpe_app_00.clas.abap) — `?app_start=z2ui5_cl_smpe_app_00`. It lists every RAP sample and opens it in a new browser tab, so the overview stays open and several samples can run side by side. *Regenerate Demo Data* in its header fills both business objects.

Fill the tables before the first run: execute `Z2UI5_CL_SMPE_DATA_TRV` and `Z2UI5_CL_SMPE_DATA_TRD` with F9 in ADT, or press *Regenerate Demo Data* in the overview (*Generate Demo Data* in a single sample does the same for its own business object). Both offer `data_generate( )`, `data_delete( )` and `data_reset( )`.

Demo data is created through the business object, not with an `INSERT` — otherwise the determinations would not run and the rows would be data the BO could never produce.

## The business object

Both business objects manage the same thing: a **travel**. They are ordinary managed RAP BOs — small on purpose, but not so small that consuming them is uninteresting.

| Field | |
|---|---|
| `TravelId` | the readable key, 8 digits. **Assigned by the BO**, never by the caller |
| `AgencyId`, `CustomerId` | mandatory |
| `BeginDate`, `EndDate` | mandatory, and `EndDate` must not be before `BeginDate` |
| `BookingFee`, `CurrencyCode` | what the caller may write |
| `TotalPrice` | **readonly** — the BO derives it |
| `OverallStatus` | **readonly** — `O` open, `A` accepted, `X` rejected |
| `Description` | free text |
| `CreatedBy/At`, `LastChangedBy/At` | **readonly** — filled by the runtime |

What runs, and **when**, is the part that surprises most newcomers:

- **Early numbering** hands out `TravelId` while the CREATE is still in the transactional buffer. That is why the new key comes back in `MAPPED` under the `%cid` you sent, and why you never pass a key on CREATE.
- A **determination** (`setInitialValues`) fills `OverallStatus`, `TotalPrice` and the currency right after a create. Those fields are readonly for you precisely because the BO owns them.
- Two **validations** (`validateCustomer`, `validateDates`) run **on save**, not at the `MODIFY`. A `MODIFY` that answered with an empty `FAILED` can still be refused at the `COMMIT` — which is why the samples always evaluate both responses.
- Two **actions** (`acceptTravel`, `rejectTravel`) set `OverallStatus`. An action is called with `EXECUTE`.

`Z2UI5_R_SMPE_TRD` is the same BO **with draft**. Two things change:

- The key is a `TravelUuid`, and the draft and the active instance **share it** — `%is_draft` is the only thing separating them. That single fact is what samples 06–10 are built on.
- `TravelId` is only handed out when a draft is **activated**, so a discarded draft does not burn a number.

Both BOs are independent of each other; you can look at either one first.

## Find the snippet

Ten samples, each one statement, plus two complete apps. The numbers are the reading order.

| You want to | Statement | Sample |
|---|---|---|
| read an instance | `READ ENTITIES` | [`01`](src/01/z2ui5_cl_smpe_app_01.clas.abap) |
| create one | `MODIFY … CREATE` → `MAPPED` | [`02`](src/01/z2ui5_cl_smpe_app_02.clas.abap) |
| change fields | `MODIFY … UPDATE FIELDS` | [`03`](src/01/z2ui5_cl_smpe_app_03.clas.abap) |
| delete one | `MODIFY … DELETE FROM` | [`04`](src/01/z2ui5_cl_smpe_app_04.clas.abap) |
| see which instances have a draft | `READ … %is_draft = mk-on` | [`06`](src/02/z2ui5_cl_smpe_app_06.clas.abap) |
| enter draft mode | `EXECUTE Edit` / `Resume` | [`07`](src/02/z2ui5_cl_smpe_app_07.clas.abap) |
| change a draft | `UPDATE … %is_draft = mk-on` | [`08`](src/02/z2ui5_cl_smpe_app_08.clas.abap) |
| leave draft mode | `EXECUTE Activate` / `Discard` | [`09`](src/02/z2ui5_cl_smpe_app_09.clas.abap) |
| show BO messages in the UI | `msg_get_collect( )` | [`context`](src/00/00/z2ui5_cl_smpe_context.clas.abap) |

Samples 01–04 run against the business object without draft, 06–09 against the draft enabled one. Start at 06 for the draft half — it carries the one trick the other three reuse.

**The two complete apps** are a different kind of sample. They repeat what the single statements show, but in one screen with popups, message handling and a refresh — roughly three times the size. Read them after the snippets, not instead of them:

| | | |
|---|---|---|
| call a BO action, save and catch what failed | `MODIFY … EXECUTE`, `COMMIT ENTITIES RESPONSE OF` | [`05` manage travels](src/01/z2ui5_cl_smpe_app_05.clas.abap) |
| the whole draft lifecycle | everything from 06–09 | [`10` manage travels with draft](src/02/z2ui5_cl_smpe_app_10.clas.abap) |

## The snippets

**Read** — no SELECT, no OData.

```abap
READ ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    ALL FIELDS WITH VALUE #( ( travelid = travel_id ) )
  RESULT DATA(t_result)
  FAILED DATA(s_failed).
```

A key that does not exist is not an exception — it lands in `FAILED`, and `RESULT` simply has one row less. The response is what you check, never `sy-subrc`.

**Create** — the `%cid` is yours; the key the BO assigns comes back under it.

```abap
MODIFY ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    CREATE FIELDS ( agencyid customerid begindate enddate )
    WITH VALUE #( ( %cid = `CREATE_1` agencyid = '070001' customerid = '000001' ) )
  MAPPED DATA(s_mapped)
  FAILED DATA(s_failed)
  REPORTED DATA(s_reported).

DATA(new_id) = s_mapped-travel[ %cid = `CREATE_1` ]-travelid.
```

**Update / delete / action** — same shape, only the operation differs.

```abap
UPDATE FIELDS ( description )
  WITH VALUE #( ( travelid = travel_id description = `...` ) )

DELETE FROM VALUE #( ( travelid = travel_id ) )

EXECUTE acceptTravel FROM VALUE #( ( travelid = travel_id ) )
```

**Save** — validations run here, not at the `MODIFY`.

```abap
COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trv
  FAILED DATA(s_failed)
  REPORTED DATA(s_reported).
```

**Messages** — don't loop over `%msg` yourself. abap2UI5 ships the reader: it recognises a RAP structure by `%MSG`/`%FAIL`, takes a whole `REPORTED` response or a single entity table, and pulls out the failure cause, element, action, `%cid` and `%tky`.

```abap
client->message_box_display( text = z2ui5_cl_util=>msg_get_collect( s_reported-travel )
                             type = `Error` ).
```

**Drafts** — a draft shares the key of its active instance, so `%is_draft` is the only thing separating them. Everything that comes back in `RESULT` has a draft, the rest lands in `FAILED`.

```abap
READ ENTITIES OF z2ui5_r_smpe_trd
  ENTITY travel
    FIELDS ( travelid ) WITH VALUE #( FOR s_row IN t_result
                                      ( %tky = VALUE #( traveluuid = s_row-traveluuid
                                                        %is_draft  = if_abap_behv=>mk-on ) ) )
  RESULT DATA(t_drafts)
  FAILED DATA(s_failed).
```

A draft action needs the key and nothing else — which of the two instances it works on is part of the action, not of the call. `%is_draft` is not even a component of the action import type.

```abap
EXECUTE Edit     FROM VALUE #( ( %key-traveluuid = uuid ) )   " active -> new draft
EXECUTE Resume   FROM VALUE #( ( %key-traveluuid = uuid ) )   " draft  -> continue it
EXECUTE Activate FROM VALUE #( ( %key-traveluuid = uuid ) )   " draft  -> active, validations run
EXECUTE Discard  FROM VALUE #( ( %key-traveluuid = uuid ) )   " draft  -> gone, active untouched
```

---

# Smart Controls

`src/03`. The `sap.ui.comp` library builds its UI from **OData V2 metadata**, not from
ABAP data — a `SmartTable` asks the service what the columns are, a `SmartField`
asks what the field is. So these apps carry almost no data of their own; they
switch the default model to a service and let the metadata do the rest.

Two consequences you cannot get around:

- **SAPUI5, not OpenUI5.** `sap.ui.comp` is not part of the OpenUI5 distribution.
- **An activated OData V2 service.** Most of the samples point at the Gateway demo
  service `GWSAMPLE_BASIC`, which ships with every on-premise system and only has
  to be activated once in `/IWFND/MAINT_SERVICE`. Where a sample needs a different
  service, it says so at the `switch_default_model_path` — adjust it to your system.

| Sample | Shows | Service |
|---|---|---|
| [`313`](src/03/z2ui5_cl_smpe_app_313.clas.abap) | SmartFilterBar + SmartTable with variant management | `UI_PRODUCTLIST` |
| [`314`](src/03/z2ui5_cl_smpe_app_314.clas.abap) | switch the default model — device, HTTP and OData model side by side | `GWSAMPLE_BASIC` |
| [`319`](src/03/z2ui5_cl_smpe_app_319.clas.abap) | SmartMultiInput → an ABAP `SELECT-OPTIONS` range table | `UI_PRODUCTLIST` + value list annotations |
| [`475`](src/03/z2ui5_cl_smpe_app_475.clas.abap) | SmartField inside a SmartForm | `GWSAMPLE_BASIC` |
| [`476`](src/03/z2ui5_cl_smpe_app_476.clas.abap) | SmartForm, display/edit toggle | `GWSAMPLE_BASIC` |
| [`477`](src/03/z2ui5_cl_smpe_app_477.clas.abap) | SmartFilterBar driving a SmartTable | `GWSAMPLE_BASIC` |
| [`478`](src/03/z2ui5_cl_smpe_app_478.clas.abap) | page variant management | `GWSAMPLE_BASIC` |
| [`479`](src/03/z2ui5_cl_smpe_app_479.clas.abap) | SmartChart with NavigationPopover | **an analytical service — you must supply it** |

`319` is the interesting one if you write classic ABAP: the user gets a full
SELECT-OPTIONS experience in the browser (value help, several conditions,
`contains` / `between` / `greater-than`, include and exclude), and the app maps the
returned conditions 1:1 onto an ABAP range table — `SIGN`/`OPTION`/`LOW`/`HIGH` — and
filters with `... WHERE product_type IN r_product_type`. Both the derived
SELECT-OPTIONS and the matching rows are on screen, so the mapping is visible.

`479` cannot fall back to `GWSAMPLE_BASIC`: a SmartChart needs an **analytical**
OData V2 service — properties marked `sap:aggregation-role` dimension/measure plus
the `UI.Chart` annotation the layout comes from. No such service is part of a
standard system, so the path in the class is a placeholder and the chart stays
empty until you point it at a real one.

---

# OData

`src/04`. No smart controls — a plain `sap.m.Table` bound to an OData V2 model.

[`315`](src/04/z2ui5_cl_smpe_app_315.clas.abap) attaches **two** models in one view
via `cs_event-set_odata_model`, each under its own name, and binds one table to
each: `{TRAVEL>/Currency}` and `{FLIGHT>/Airport}`. The column headers come from the
metadata (`{TRAVEL>/#Currency/Currency/@sap:label}`), the cells from the entity.

It expects `/sap/opu/odata/DMO/API_TRAVEL_U_V2/` and
`/sap/opu/odata/DMO/ui_flight_r_v2/` — the services of the SAP flight reference
scenario. Swap the paths for services of your own system if those are not
activated.

---

# Stateful Sessions / Locks

`src/05`. By default abap2UI5 is stateless: every roundtrip is a fresh request and
the app state travels in the payload. `client->set_session_stateful( )` turns that
off — the session sticks to one work process, which is what you need the moment you
want an **ABAP lock** to survive between two clicks.

| Sample | Shows |
|---|---|
| [`486`](src/05/z2ui5_cl_smpe_app_486.clas.abap) | the basics — a counter in a static container. It keeps counting up while the session is stateful and starts over once you switch it off |
| [`485`](src/05/z2ui5_cl_smpe_app_485.clas.abap) | set an `ENQUEUE` lock, read it back with `ENQUEUE_READ`, end and restart the session |
| [`490`](src/05/z2ui5_cl_smpe_app_490.clas.abap) | one lock per screen — every *Next Lock View* navigates into a new app instance that takes the next `VARKEY`, going back releases it |

**On-premise only.** The locks go through the function modules `ENQUEUE_E_TABLE` and
`ENQUEUE_READ`, which are not released for ABAP Cloud — `485`'s own page title says
so. The lock table `Z2UI5_T_SMPE_01` comes with the repository (`src/05/01`); after
the import it only has to be activated, it is never filled with data. If you want to
watch the entries appear, keep `SM12` open next to the browser.

---

# AMC/APC — WebSockets

`src/06`. A news feed pushed from ABAP into every open browser tab, **without a line
of JavaScript**: the abap2UI5 custom control `z2ui5:Websocket` keeps the connection
open, reports every inbound message through its `received` event and a failure
through `error`; publishing goes the other way, from ABAP into the AMC channel.

| Object | Role |
|---|---|
| [`489`](src/06/z2ui5_cl_smpe_app_489.clas.abap) | the app — connect, publish, list the active connections |
| [`489_ws`](src/06/z2ui5_cl_smpe_app_489_ws.clas.abap) | the APC handler, `CL_APC_WSP_EXT_STATELESS_BASE` |
| `Z2UI5_AMC_SMP_2` | the messaging channel, `/news_feed` |
| `Z2UI5_APC_SMP_2` | the push channel and its ICF node |

**Setup:** activate the ICF service `/sap/bc/apc/sap/z2ui5_apc_smp_2` in `SICF`. The
app checks this itself and shows a warning strip if the node is inactive, so you
notice before you wonder why nothing arrives. On-premise only — APC/AMC is not part
of ABAP Cloud.

---

# MIME Play Audio

`src/07`. [`487`](src/07/z2ui5_cl_smpe_app_487.clas.abap) plays a sound stored in the
**MIME repository**, addressed by its ICF path — a success and an error tone, both
shipped with the repository (`src/07/01`).

**Setup:** activate the ICF service `/SAP/PUBLIC/BC/ABAP/mime_demo` in `SICF`. The app
checks the node and warns if it is inactive.

Type the magic key the app tells you and you get the success sound; type anything
else and you get the error one.

---

## Structure

```
src/                 z2ui5_cl_smpe_app_00 - the overview app of the RAP samples
src/00/00            context shared by the RAP samples
src/01               RAP, no draft            samples 01-05
src/01/01            the business object      Z2UI5_R_SMPE_TRV, Z2UI5_T_SMPE_TRV
src/02               RAP with draft           samples 06-10
src/02/02            the business object      Z2UI5_R_SMPE_TRD, Z2UI5_T_SMPE_TRD, Z2UI5_D_SMPE_TRD
src/03               Smart Controls           samples 313, 314, 319, 475-479
src/04               OData                    sample 315
src/05               Stateful Sessions/Locks  samples 485, 486, 490
src/05/01            the lock table           Z2UI5_T_SMPE_01
src/06               AMC/APC                  sample 489
src/06/01            channel, push channel, ICF node
src/07               MIME Play Audio          sample 487
src/07/01            the two MIME objects
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

The exceptions are the objects abaplint cannot name-check at all — the AMC channel,
the APC push channel with its ICF node, and the two MIME objects. They still carry
the older `SMP` token (`Z2UI5_AMC_SMP_2`, `Z2UI5_APC_SMP_2`, `z2ui5_smp_error.mp3`,
`z2ui5_smp_success.mp3`).

## Checks

| Workflow | What it does |
|---|---|
| `abap-standard` | `abaplint ./abaplint.jsonc` — syntax `v757`, the on-premise release |
| `abap-cloud` | `abaplint .github/abaplint/abap_cloud.jsonc` — the ABAP Cloud language version |
| `check-abap2UI5` | [`abap2ui5lint`](https://github.com/abap2UI5/linter) — the app class and the view it produces, together |

There is no `abap-702` counterpart and no derived branch: EML needs ABAP Platform
>= 1909, so unlike the other sample repositories this one is not downported.

Two caveats about the badges:

- abaplint parses EML but does not resolve behavior definitions, so entity, alias and
  action names inside EML statements are **not** checked, and neither are the
  `.asbdef` files.
- `abap-cloud` lints the whole tree, including the areas that are on-premise only by
  design (`src/05` `ENQUEUE`, `src/06` APC/AMC). It reports those as errors — a red
  cloud badge does not mean the RAP samples are broken.
