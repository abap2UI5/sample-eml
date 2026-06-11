# abap2UI5 — Working with EML

Sample apps that show how to consume a RAP Business Object with the **Entity Manipulation Language (EML)** inside an [abap2UI5](https://github.com/abap2UI5/abap2UI5) app.

abap2UI5 apps are plain ABAP classes — so everything you learned about EML in the official RAP tutorials works here too. Instead of exposing the RAP BO via OData and Fiori Elements, the abap2UI5 app calls the BO directly with EML and renders the UI itself.

## Background — the RAP Tutorials

These samples transfer the EML patterns taught in the official SAP tutorials into the abap2UI5 context:

| Tutorial | Content |
|---|---|
| [abap-platform-refscen-flight](https://github.com/SAP-samples/abap-platform-refscen-flight) | Flight reference scenario — provides the RAP BOs `/DMO/I_TRAVEL_M` and `/DMO/R_TRAVEL_D` used by these samples |
| [abap-platform-rap-opensap](https://github.com/SAP-samples/abap-platform-rap-opensap) | openSAP course *Building Apps with RAP* — week 5/6 covers local BO consumption with EML |
| [cloud-abap-rap](https://github.com/SAP-samples/cloud-abap-rap) | RAP examples for SAP BTP ABAP Environment |
| [abap-platform-rap-workshops](https://github.com/SAP-samples/abap-platform-rap-workshops) | RAP workshop material (RAP100/RAP110), including EML exercises |

## Prerequisites

* [abap2UI5](https://github.com/abap2UI5/abap2UI5) installed
* The flight reference scenario installed ([abap-platform-refscen-flight](https://github.com/SAP-samples/abap-platform-refscen-flight)) — it ships the RAP BOs `/DMO/I_TRAVEL_M` (*managed* scenario) and `/DMO/R_TRAVEL_D` (*draft* scenario) incl. demo data generator
* ABAP Platform >= 1909 (on-premise) or SAP BTP ABAP Environment — EML is not available on older releases, so unlike other abap2UI5 sample repositories this one is **not** downported to NW 7.02

Install this repository with [abapGit](https://abapgit.org) and start the apps like any other abap2UI5 app (e.g. add them to your startup app or call them via the generic HTTP handler).

## The Samples

### 1. `z2ui5_cl_sample_eml_read` — Read a Travel

The smallest possible EML roundtrip: enter a travel id, press *Read* and the app reads the instance from the RAP BO — no SELECT, no OData:

```abap
READ ENTITIES OF /dmo/i_travel_m
  ENTITY travel
    ALL FIELDS WITH VALUE #( ( travel_id = travel_id ) )
  RESULT DATA(t_result)
  FAILED DATA(s_failed).
```

The `FAILED` response is checked to show an error message when the instance does not exist.

### 2. `z2ui5_cl_sample_eml_crud` — Manage Travels

A complete transactional app on top of `/DMO/I_TRAVEL_M`. The travel list is read from the CDS view; every change goes through the RAP BO with EML, so all validations, determinations and feature controls of the behavior definition are executed:

* **Create** — popup form, then `MODIFY ENTITIES ... CREATE FIELDS ... WITH` with a `%cid`; thanks to *early numbering* the new key is returned in `MAPPED` and shown to the user
* **Update** — the description column is editable, *Save* triggers `MODIFY ENTITIES ... UPDATE FIELDS ( description )`
* **Actions** — *Accept*/*Reject* call the BO actions via `MODIFY ENTITIES ... EXECUTE acceptTravel / rejectTravel`
* **Delete** — `MODIFY ENTITIES ... DELETE FROM`
* **Save** — `COMMIT ENTITIES RESPONSE OF /dmo/i_travel_m` with `FAILED`/`REPORTED` handling; on failure the messages raised by the BO (e.g. from the validations `validateCustomer`, `validateDates`, ...) are displayed in a message box and the transactional buffer is cleared with `ROLLBACK ENTITIES`

The typical pattern used in every event handler:

```abap
MODIFY ENTITIES OF /dmo/i_travel_m
  ENTITY travel
    EXECUTE acceptTravel FROM VALUE #( ( travel_id = travel_id ) )
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

### 3. `z2ui5_cl_sample_eml_draft` — Draft Handling

The full draft roundtrip on the draft-enabled BO `/DMO/R_TRAVEL_D` — the same lifecycle a Fiori Elements app runs through, executed manually with EML:

* **Edit** — the draft action `Edit` copies the active instance into a new draft (`%tky` with `%is_draft = if_abap_behv=>mk-off` addresses the active instance):

  ```abap
  MODIFY ENTITIES OF /dmo/r_travel_d
    ENTITY travel
      EXECUTE Edit FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                                   %is_draft  = if_abap_behv=>mk-off ) ) )
    FAILED s_failed
    REPORTED s_reported.
  ```

* **Save Draft** — `MODIFY ... UPDATE` with `%is_draft = mk-on` plus `COMMIT ENTITIES` persists the draft in the draft table `/dmo/d_travel_d`; the changes survive the session and even a logoff, without any validation having to pass yet
* **Resume** — when a travel already has a draft, the draft action `Resume` reactivates it and the user continues exactly where the last session ended
* **Activate** — the draft action `Activate` turns the draft into the active instance; the BO validations run during activation, so an invalid draft stays a draft and the messages are displayed
* **Discard** — the draft action `Discard` deletes the draft, the active instance stays untouched
* **Draft indicator** — the travel list marks instances with an existing draft by reading the keys with `%is_draft = mk-on`: a draft shares the key of its active instance, so every key returned in `RESULT` has a draft (the rest comes back in `FAILED`)

## Why EML + abap2UI5?

* One transactional programming model — the same BO serves your Fiori Elements app and your abap2UI5 app
* All business logic (validations, determinations, authorizations, feature control) stays in the RAP BO
* No OData service, no UI annotations needed — the abap2UI5 view is built in plain ABAP
