[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__smpe-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![abap-standard](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-standard.yaml)
[![abap-cloud](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-cloud.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-cloud.yaml)
<br>
[![check-abap2UI5](https://github.com/abap2UI5/sample-eml/actions/workflows/check-abap2UI5.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/check-abap2UI5.yaml)

# abap2UI5 — Working with EML

Sample apps that show how to consume a RAP Business Object with the **Entity Manipulation Language (EML)** inside an [abap2UI5](https://github.com/abap2UI5/abap2UI5) app.

abap2UI5 apps are plain ABAP classes — so everything you learned about EML in the official RAP tutorials works here too. Instead of exposing the RAP BO via OData and Fiori Elements, the abap2UI5 app calls the BO directly with EML and renders the UI itself.

**The business objects ship with this repository.** There is nothing else to install: no flight reference scenario, no demo data generator, no other sample repository. Pull it with abapGit, run an app, press *Generate Demo Data* — that is the whole setup. See [Demo Data](#demo-data) if you would rather fill the tables from ADT.

## Prerequisites

* [abap2UI5](https://github.com/abap2UI5/abap2UI5) installed
* ABAP Platform >= 1909 (on-premise) or SAP BTP ABAP Environment — EML is not available on older releases, so unlike other abap2UI5 sample repositories this one is **not** downported to NW 7.02

Install this repository with [abapGit](https://abapgit.org) and start the apps like any other abap2UI5 app (e.g. add them to your startup app or call them via the generic HTTP handler).

## Structure

The abap2UI5 apps sit at the top of `src` — they are what you run and what you read to learn EML. The business objects they talk to live in a subpackage each, so the RAP artifacts stay out of the way:

```
src/
│                              business object of 01, one EML statement each
├── z2ui5_cl_smpe_read         READ ENTITIES
├── z2ui5_cl_smpe_create       MODIFY ... CREATE
├── z2ui5_cl_smpe_update       MODIFY ... UPDATE
├── z2ui5_cl_smpe_delete       MODIFY ... DELETE
├── z2ui5_cl_smpe_crud         all four plus the BO actions, in one app
│
│                              business object of 02, one draft aspect each
├── z2ui5_cl_smpe_d_list       which travels have a draft?
├── z2ui5_cl_smpe_d_edit       entering draft mode: Edit / Resume
├── z2ui5_cl_smpe_d_save       changing a draft: UPDATE with %is_draft
├── z2ui5_cl_smpe_d_activate   leaving draft mode: Activate / Discard
├── z2ui5_cl_smpe_draft        the whole draft lifecycle, in one app
│
├── 01/                        RAP business object, no draft
└── 02/                        RAP business object, draft enabled
```

Every app in the two upper groups does exactly one thing, so you can read any of them end to end in a minute. `crud` and `draft` are the same material combined into working apps — start there if you want to see a whole app, start above if you want to see a single concept.

Each subpackage holds a complete RAP stack. Nothing is shared between them, so one can be deleted without breaking the other:

| Object | [`src/01`](src/01) — no draft | [`src/02`](src/02) — draft |
|---|---|---|
| Persistent table | `Z2UI5_T_SMPE_TRV` | `Z2UI5_T_SMPE_TRD` |
| Draft table | — | `Z2UI5_D_SMPE_TRD` |
| Root view entity | `Z2UI5_R_SMPE_TRV` | `Z2UI5_R_SMPE_TRD` |
| Behavior definition | `Z2UI5_R_SMPE_TRV` | `Z2UI5_R_SMPE_TRD` |
| Behavior pool | `Z2UI5_CL_SMPE_BP_TRV` | `Z2UI5_CL_SMPE_BP_TRD` |
| Demo data | `Z2UI5_CL_SMPE_DATA_TRV` | `Z2UI5_CL_SMPE_DATA_TRD` |

Both business objects model the same thing — a travel with an agency, a customer, a date range, a booking fee and a status — so the two stay comparable and the only real difference is the draft handling.

### What the business objects implement

The point of consuming a RAP BO is that the business logic runs no matter who triggers the operation. Both BOs therefore carry more than plain CRUD:

* **Early numbering** (`src/01`) — the readable key is drawn in `earlynumbering_create` and handed back in `MAPPED`
* **Managed numbering + a determination** (`src/02`) — the UUID key comes from the runtime, the readable number is assigned by a `determination ... on save`, so a discarded draft does not burn one
* **Determination `setInitialValues`** — sets the initial status and the total price on create
* **Validations `validateCustomer` and `validateDates`** — run `on save`, i.e. during `COMMIT ENTITIES` and, for the draft BO, during `Activate`
* **Actions `acceptTravel` and `rejectTravel`** — declared with `result [1] $self`, so they return the changed instance
* **Global authorization** — implemented, but deliberately granting everything; a productive BO would check an authorization object here

## Demo Data

Both business objects start out empty, and abapGit does not carry table content — so the data has to be produced in every system. One class per business object does that:

| | run it |
|---|---|
| `Z2UI5_CL_SMPE_DATA_TRV` / `..._TRD` | in ADT press F9 — both are console applications (`if_oo_adt_classrun`) |
| | or press *Generate Demo Data* in any app that offers it — the button calls the same `reset( )` |

`reset( )` deletes everything and creates a fixed set again. Deleting first is what makes the keys predictable: early numbering continues behind `MAX( travel_id )`, so on an empty table the demo travels always come out as 1, 2, 3 — which is what lets the *Read a Travel* sample tell you to enter `1`.

The data is created **through the business object with EML**, never with an `INSERT` into the table. An `INSERT` would be shorter and is what SAP's own flight data generator does, but it skips the determination `setInitialValues`, so the rows would carry no status and no total price — data this business object could never have produced itself. For the draft-enabled object the argument is even simpler: its draft table carries the admin fields of `SYCH_BDL_DRAFT_ADMIN_INC`, and creating a draft and activating it is far easier than getting those right by hand.

For **automated tests** use neither — `CL_ABAP_BEHV_TEST_ENVIRONMENT` gives you a test double of the business object, so the real tables stay untouched and the test does not depend on what happens to be in them.

## Background — the RAP Tutorials

The EML patterns shown here are the ones taught in the official SAP tutorials. Those tutorials build their own business objects too; this repository simply ships one so the samples run on their own:

| Tutorial | Content |
|---|---|
| [abap-platform-rap-opensap](https://github.com/SAP-samples/abap-platform-rap-opensap) | openSAP course *Building Apps with RAP* — week 5/6 covers local BO consumption with EML |
| [cloud-abap-rap](https://github.com/SAP-samples/cloud-abap-rap) | RAP examples for SAP BTP ABAP Environment |
| [abap-platform-rap-workshops](https://github.com/SAP-samples/abap-platform-rap-workshops) | RAP workshop material (RAP100/RAP110), including EML exercises |
| [abap-platform-refscen-flight](https://github.com/SAP-samples/abap-platform-refscen-flight) | Flight reference scenario — the BOs these samples used to depend on, kept here as a reading reference only |

## The Samples — Business Object Without Draft (`src/01`)

### 1. `z2ui5_cl_smpe_read` — Read a Travel

The smallest possible EML roundtrip: enter a travel id, press *Read* and the app reads the instance from the RAP BO — no SELECT, no OData:

```abap
READ ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    ALL FIELDS WITH VALUE #( ( travelid = travel_id ) )
  RESULT DATA(t_result)
  FAILED DATA(s_failed).
```

The `FAILED` response is checked to show an error message when the instance does not exist. The table starts out empty — run the *Create Travel* app first, all apps of `src/01` work on the same business object.

### 2. `z2ui5_cl_smpe_create` — Create a Travel

A form and one EML statement. The `%cid` is a temporary id chosen by the caller — the business object does not know the key yet, so it reports the assigned one back under that `%cid` in `MAPPED`:

```abap
MODIFY ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    CREATE FIELDS ( agencyid customerid begindate enddate bookingfee currencycode description )
    WITH VALUE #( ( %cid       = `CREATE_1`
                    agencyid   = s_travel-agency_id
                    customerid = s_travel-customer_id ) )
  MAPPED DATA(s_mapped)
  FAILED DATA(s_failed)
  REPORTED DATA(s_reported).
```

Nothing is persisted before the `COMMIT ENTITIES` — and the validations `validateCustomer` and `validateDates` only run there, so leaving the customer empty fails at the commit, not at the `MODIFY`. Thanks to *early numbering* the new key is then read from `s_mapped-travel[ %cid = 'CREATE_1' ]-travelid` and shown.

### 3. `z2ui5_cl_smpe_update` — Update a Travel

A table of travels with an editable description and one `Update` button per row:

```abap
MODIFY ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    UPDATE FIELDS ( description )
    WITH VALUE #( ( travelid    = travel_id
                    description = s_travel-description ) )
  FAILED DATA(s_failed)
  REPORTED DATA(s_reported).
```

`UPDATE FIELDS` names exactly the fields that change — everything else on the instance stays untouched, which is why nothing has to be read before the change. The list itself comes from a plain `SELECT` on the CDS view; reading needs no EML.

### 4. `z2ui5_cl_smpe_delete` — Delete a Travel

The same table with a `Delete` button per row. `DELETE` needs nothing but the key:

```abap
MODIFY ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    DELETE FROM VALUE #( ( travelid = travel_id ) )
  FAILED DATA(s_failed)
  REPORTED DATA(s_reported).
```

It can still fail — when the business object refuses the deletion or the instance is locked — which is why `FAILED` is checked here just like everywhere else.

### 5. `z2ui5_cl_smpe_crud` — Manage Travels

A complete transactional app on top of `Z2UI5_R_SMPE_TRV`. The travel list is read from the CDS view; every change goes through the RAP BO with EML, so all validations, determinations and feature controls of the behavior definition are executed:

* **Generate Demo Data** — fills the empty BO with three travels, using the same EML `CREATE` the popup uses
* **Create** — popup form, then `MODIFY ENTITIES ... CREATE FIELDS ... WITH` with a `%cid`; thanks to *early numbering* the new key is returned in `MAPPED` and shown to the user
* **Update** — the description column is editable, *Save* triggers `MODIFY ENTITIES ... UPDATE FIELDS ( description )`
* **Actions** — *Accept*/*Reject* call the BO actions via `MODIFY ENTITIES ... EXECUTE acceptTravel / rejectTravel`
* **Delete** — `MODIFY ENTITIES ... DELETE FROM`
* **Save** — `COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trv` with `FAILED`/`REPORTED` handling; on failure the messages raised by the BO (e.g. from the validations `validateCustomer`, `validateDates`) are displayed in a message box and the transactional buffer is cleared with `ROLLBACK ENTITIES`

The typical pattern used in every event handler:

```abap
MODIFY ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    EXECUTE acceptTravel FROM VALUE #( ( travelid = travel_id ) )
  FAILED DATA(s_failed)
  REPORTED DATA(s_reported).

IF s_failed-travel IS NOT INITIAL.

  ROLLBACK ENTITIES.
  messages_display( s_reported-travel ).
  RETURN.

ENDIF.

IF data_save( ) = abap_true. " COMMIT ENTITIES RESPONSE OF ...
  data_read( ).
  client->view_model_update( ).
ENDIF.
```

## The Samples — Business Object With Draft (`src/02`)

Draft handling is the one part of RAP where an app has to think about *which* instance it is addressing: the draft or the active one. Each of the next four apps isolates one aspect of that, the fifth puts them back together.

### 1. `z2ui5_cl_smpe_d_list` — Which Travels Have a Draft?

Read-only, and the foundation for everything below. A draft shares the key of its active instance — only `%is_draft` tells them apart. So asking "which travels have a draft?" is a read of the keys with `%is_draft = mk-on`: everything that comes back in `RESULT` has one, the rest lands in `FAILED`.

```abap
READ ENTITIES OF z2ui5_r_smpe_trd
  ENTITY travel
    FIELDS ( travelid ) WITH VALUE #( FOR s_row IN t_result
                                      ( %tky = VALUE #( traveluuid = s_row-traveluuid
                                                        %is_draft  = if_abap_behv=>mk-on ) ) )
  RESULT DATA(t_drafts)
  FAILED DATA(s_failed).
```

### 2. `z2ui5_cl_smpe_d_edit` — Entering Draft Mode

One button per travel, and it does one of two things depending on whether a draft already exists. That is the whole aspect: `Edit` and `Resume` are the two doors into the same room.

```abap
" no draft yet - Edit copies the ACTIVE instance into a new draft
EXECUTE Edit FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                             %is_draft  = if_abap_behv=>mk-off ) ) )

" a draft exists - Edit would fail, Resume picks the DRAFT up again
EXECUTE Resume FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                               %is_draft  = if_abap_behv=>mk-on ) ) )
```

Note the `%is_draft` values: `Edit` addresses the active instance because that is the only one that exists yet, `Resume` addresses the draft.

### 3. `z2ui5_cl_smpe_d_save` — Changing a Draft

An ordinary `UPDATE`. The only thing that makes it a draft update is `%is_draft = mk-on` in the key:

```abap
MODIFY ENTITIES OF z2ui5_r_smpe_trd
  ENTITY travel
    UPDATE FIELDS ( description )
    WITH VALUE #( ( %tky        = VALUE #( traveluuid = uuid
                                           %is_draft  = if_abap_behv=>mk-on )
                    description = s_draft-description ) )
  FAILED DATA(s_failed)
  REPORTED DATA(s_reported).
```

Watch what does *not* happen at the `COMMIT ENTITIES`: no validation runs. The draft is written to `Z2UI5_D_SMPE_TRD` even if it is incomplete or plainly wrong, and it survives the session and a logoff. That is the point of a draft — and the reason the validations are declared `on save`.

### 4. `z2ui5_cl_smpe_d_activate` — Leaving Draft Mode

The two ways out, side by side, because the contrast is the lesson:

```abap
" the validations run HERE - an invalid draft stays a draft
EXECUTE Activate FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                                 %is_draft  = if_abap_behv=>mk-on ) ) )

" throws the changes away, the active travel is untouched
EXECUTE Discard FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                                %is_draft  = if_abap_behv=>mk-on ) ) )
```

`Activate` is the moment the `on save` validations `validateCustomer` and `validateDates` finally execute. If one fails, nothing is lost: the draft remains, the messages come back in `REPORTED`, the user fixes it and tries again.

### 5. `z2ui5_cl_smpe_draft` — The Whole Lifecycle

All four aspects above in one app: a travel list with a draft indicator, *Edit*/*Resume* to get in, a popup to change the draft and save it, *Activate* and *Discard* to get out. It is the same lifecycle a Fiori Elements app runs through, executed manually with EML.

Read it once you have seen the four apps above — on its own it is a lot of `%is_draft` at the same time.

## Why EML + abap2UI5?

* One transactional programming model — the same BO serves your Fiori Elements app and your abap2UI5 app
* All business logic (validations, determinations, authorizations, feature control) stays in the RAP BO
* No OData service, no UI annotations needed — the abap2UI5 view is built in plain ABAP

## Notes on the CI

`abap-standard` and `abap-cloud` syntax-check the sources against the on-premise release and the ABAP Cloud language version. Two limits are worth knowing:

* abaplint parses EML statements but does not resolve behavior definitions, so entity names, alias names and action names in EML are **not** validated — only the surrounding ABAP is.
* There is no `check-rename` workflow here, unlike in the [samples](https://github.com/abap2UI5/samples) repository. Renaming the `z2ui5` namespace to a longer one for a parallel installation adds characters, and a transparent table name may not exceed 16 — which the tables of this repository already use up.
