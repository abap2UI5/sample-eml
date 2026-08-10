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

**The business objects ship with this repository.** There is nothing else to install: no flight reference scenario, no demo data generator, no other sample repository. Pull it with abapGit, run an app, press *Generate Demo Data* — that is the whole setup.

## Prerequisites

* [abap2UI5](https://github.com/abap2UI5/abap2UI5) installed
* ABAP Platform >= 1909 (on-premise) or SAP BTP ABAP Environment — EML is not available on older releases, so unlike other abap2UI5 sample repositories this one is **not** downported to NW 7.02

Install this repository with [abapGit](https://abapgit.org) and start the apps like any other abap2UI5 app (e.g. add them to your startup app or call them via the generic HTTP handler).

## Structure

The abap2UI5 apps sit at the top of `src` — they are what you run and what you read to learn EML. The business objects they talk to live in a subpackage each, so the RAP artifacts stay out of the way:

```
src/                       the abap2UI5 apps
├── z2ui5_cl_smpe_read     reads a travel from the BO of 01
├── z2ui5_cl_smpe_crud     manages the travels of the BO of 01
├── z2ui5_cl_smpe_draft    drives the draft lifecycle of the BO of 02
├── 01/                    RAP business object, no draft
└── 02/                    RAP business object, draft enabled
```

Each subpackage holds a complete RAP stack. Nothing is shared between them, so one can be deleted without breaking the other:

| Object | [`src/01`](src/01) — no draft | [`src/02`](src/02) — draft |
|---|---|---|
| Persistent table | `Z2UI5_T_SMPE_TRV` | `Z2UI5_T_SMPE_TRD` |
| Draft table | — | `Z2UI5_D_SMPE_TRD` |
| Root view entity | `Z2UI5_R_SMPE_TRV` | `Z2UI5_R_SMPE_TRD` |
| Behavior definition | `Z2UI5_R_SMPE_TRV` | `Z2UI5_R_SMPE_TRD` |
| Behavior pool | `Z2UI5_CL_SMPE_BP_TRV` | `Z2UI5_CL_SMPE_BP_TRD` |

Both business objects model the same thing — a travel with an agency, a customer, a date range, a booking fee and a status — so the two stay comparable and the only real difference is the draft handling.

### What the business objects implement

The point of consuming a RAP BO is that the business logic runs no matter who triggers the operation. Both BOs therefore carry more than plain CRUD:

* **Early numbering** (`src/01`) — the readable key is drawn in `earlynumbering_create` and handed back in `MAPPED`
* **Managed numbering + a determination** (`src/02`) — the UUID key comes from the runtime, the readable number is assigned by a `determination ... on save`, so a discarded draft does not burn one
* **Determination `setInitialValues`** — sets the initial status and the total price on create
* **Validations `validateCustomer` and `validateDates`** — run `on save`, i.e. during `COMMIT ENTITIES` and, for the draft BO, during `Activate`
* **Actions `acceptTravel` and `rejectTravel`** — declared with `result [1] $self`, so they return the changed instance
* **Global authorization** — implemented, but deliberately granting everything; a productive BO would check an authorization object here

## Background — the RAP Tutorials

The EML patterns shown here are the ones taught in the official SAP tutorials. Those tutorials build their own business objects too; this repository simply ships one so the samples run on their own:

| Tutorial | Content |
|---|---|
| [abap-platform-rap-opensap](https://github.com/SAP-samples/abap-platform-rap-opensap) | openSAP course *Building Apps with RAP* — week 5/6 covers local BO consumption with EML |
| [cloud-abap-rap](https://github.com/SAP-samples/cloud-abap-rap) | RAP examples for SAP BTP ABAP Environment |
| [abap-platform-rap-workshops](https://github.com/SAP-samples/abap-platform-rap-workshops) | RAP workshop material (RAP100/RAP110), including EML exercises |
| [abap-platform-refscen-flight](https://github.com/SAP-samples/abap-platform-refscen-flight) | Flight reference scenario — the BOs these samples used to depend on, kept here as a reading reference only |

## The Samples

### 1. `z2ui5_cl_smpe_read` — Read a Travel

The smallest possible EML roundtrip: enter a travel id, press *Read* and the app reads the instance from the RAP BO — no SELECT, no OData:

```abap
READ ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    ALL FIELDS WITH VALUE #( ( travelid = travel_id ) )
  RESULT DATA(t_result)
  FAILED DATA(s_failed).
```

The `FAILED` response is checked to show an error message when the instance does not exist. The table starts out empty — create a travel in the *Manage Travels* app first, both apps work on the same business object.

### 2. `z2ui5_cl_smpe_crud` — Manage Travels

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

### 3. `z2ui5_cl_smpe_draft` — Draft Handling

The full draft roundtrip on the draft-enabled BO `Z2UI5_R_SMPE_TRD` — the same lifecycle a Fiori Elements app runs through, executed manually with EML:

* **Generate Demo Data** — creates the travels as *drafts* and then activates them, which is the complete lifecycle in two EML round trips
* **Edit** — the draft action `Edit` copies the active instance into a new draft (`%tky` with `%is_draft = if_abap_behv=>mk-off` addresses the active instance):

  ```abap
  MODIFY ENTITIES OF z2ui5_r_smpe_trd
    ENTITY travel
      EXECUTE Edit FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                                   %is_draft  = if_abap_behv=>mk-off ) ) )
    FAILED s_failed
    REPORTED s_reported.
  ```

* **Save Draft** — `MODIFY ... UPDATE` with `%is_draft = mk-on` plus `COMMIT ENTITIES` persists the draft in the draft table `Z2UI5_D_SMPE_TRD`; the changes survive the session and even a logoff, without any validation having to pass yet
* **Resume** — when a travel already has a draft, the draft action `Resume` reactivates it and the user continues exactly where the last session ended
* **Activate** — the draft action `Activate` turns the draft into the active instance; the BO validations run during activation, so an invalid draft stays a draft and the messages are displayed
* **Discard** — the draft action `Discard` deletes the draft, the active instance stays untouched
* **Draft indicator** — the travel list marks instances with an existing draft by reading the keys with `%is_draft = mk-on`: a draft shares the key of its active instance, so every key returned in `RESULT` has a draft (the rest comes back in `FAILED`)

## Why EML + abap2UI5?

* One transactional programming model — the same BO serves your Fiori Elements app and your abap2UI5 app
* All business logic (validations, determinations, authorizations, feature control) stays in the RAP BO
* No OData service, no UI annotations needed — the abap2UI5 view is built in plain ABAP

## Notes on the CI

`abap-standard` and `abap-cloud` syntax-check the sources against the on-premise release and the ABAP Cloud language version. Two limits are worth knowing:

* abaplint parses EML statements but does not resolve behavior definitions, so entity names, alias names and action names in EML are **not** validated — only the surrounding ABAP is.
* There is no `check-rename` workflow here, unlike in the [samples](https://github.com/abap2UI5/samples) repository. Renaming the `z2ui5` namespace to a longer one for a parallel installation adds characters, and a transparent table name may not exceed 16 — which the tables of this repository already use up.
