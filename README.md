[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__smpe-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![abap-standard](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-standard.yaml)
[![abap-cloud](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-cloud.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-cloud.yaml)
[![check-abap2UI5](https://github.com/abap2UI5/sample-eml/actions/workflows/check-abap2UI5.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/check-abap2UI5.yaml)

# abap2UI5 — EML Snippets

Consuming a RAP business object with EML from an [abap2UI5](https://github.com/abap2UI5/abap2UI5) app: no OData service, no annotations, the view is built in plain ABAP.

You already know EML. This repository shows where it goes in an app — one runnable sample per statement, plus the two business objects to run them against, so nothing else has to be installed.

## Find the snippet

| You want to | Statement | Sample |
|---|---|---|
| read an instance | `READ ENTITIES` | [`read`](src/01/z2ui5_cl_smpe_read.clas.abap) |
| create one | `MODIFY … CREATE` → `MAPPED` | [`create`](src/01/z2ui5_cl_smpe_create.clas.abap) |
| change fields | `MODIFY … UPDATE FIELDS` | [`update`](src/01/z2ui5_cl_smpe_update.clas.abap) |
| delete one | `MODIFY … DELETE FROM` | [`delete`](src/01/z2ui5_cl_smpe_delete.clas.abap) |
| call a BO action | `MODIFY … EXECUTE` | [`crud`](src/01/z2ui5_cl_smpe_crud.clas.abap) |
| save and catch what failed | `COMMIT ENTITIES RESPONSE OF` | [`crud`](src/01/z2ui5_cl_smpe_crud.clas.abap) |
| show BO messages in the UI | `msg_get_collect( )` | [`context`](src/00/00/z2ui5_cl_smpe_context.clas.abap) |
| see which instances have a draft | `READ … %is_draft = mk-on` | [`d_list`](src/02/z2ui5_cl_smpe_d_list.clas.abap) |
| enter draft mode | `EXECUTE Edit` / `Resume` | [`d_edit`](src/02/z2ui5_cl_smpe_d_edit.clas.abap) |
| change a draft | `UPDATE … %is_draft = mk-on` | [`d_save`](src/02/z2ui5_cl_smpe_d_save.clas.abap) |
| leave draft mode | `EXECUTE Activate` / `Discard` | [`d_activate`](src/02/z2ui5_cl_smpe_d_activate.clas.abap) |
| see a whole app | everything above | [`crud`](src/01/z2ui5_cl_smpe_crud.clas.abap), [`draft`](src/02/z2ui5_cl_smpe_draft.clas.abap) |

## The snippets

**Read** — no SELECT, no OData.

```abap
READ ENTITIES OF z2ui5_r_smpe_trv
  ENTITY travel
    ALL FIELDS WITH VALUE #( ( travelid = travel_id ) )
  RESULT DATA(t_result)
  FAILED DATA(s_failed).
```

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

```abap
EXECUTE Edit     FROM ... %is_draft = mk-off   " active -> new draft
EXECUTE Resume   FROM ... %is_draft = mk-on    " draft  -> continue it
EXECUTE Activate FROM ... %is_draft = mk-on    " draft  -> active, validations run
EXECUTE Discard  FROM ... %is_draft = mk-on    " draft  -> gone, active untouched
```

## Setup

1. Install [abap2UI5](https://github.com/abap2UI5/abap2UI5).
2. Pull this repository with [abapGit](https://abapgit.org). ABAP Platform >= 1909 or BTP ABAP Environment — EML needs it, so unlike the other sample repositories this one is not downported to 7.02.
3. Fill the tables: run `Z2UI5_CL_SMPE_DATA_TRV` and `Z2UI5_CL_SMPE_DATA_TRD` with F9 in ADT, or press *Generate Demo Data* in a sample. Both offer `data_generate( )`, `data_delete( )` and `data_reset( )`.

Demo data is created through the business object, not with an `INSERT` — otherwise the determinations would not run and the rows would be data the BO could never produce.

## Structure

```
src/00/00        context shared by the samples
src/00/01/01     RAP business object, no draft         Z2UI5_R_SMPE_TRV
src/00/01/02     RAP business object, draft enabled    Z2UI5_R_SMPE_TRD
src/01           samples on the business object of 00/01/01
src/02           samples on the business object of 00/01/02
src/03           events — to be filled
```

The two business objects are ordinary managed BOs with early numbering, a determination, two validations and two actions — enough that consuming them with EML is worth showing. They are independent of each other.

---

One caveat about the green badges above: abaplint parses EML but does not resolve behavior definitions, so entity, alias and action names inside EML statements are **not** checked, and neither are the `.asbdef` files.
