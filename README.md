[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__smpe-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![abap-standard](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-standard.yaml)
[![abap-cloud](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-cloud.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/abap-cloud.yaml)
[![check-abap2UI5](https://github.com/abap2UI5/sample-eml/actions/workflows/check-abap2UI5.yaml/badge.svg)](https://github.com/abap2UI5/sample-eml/actions/workflows/check-abap2UI5.yaml)

# abap2UI5 — samples-rap

Consuming a RAP business object with EML from an [abap2UI5](https://github.com/abap2UI5/abap2UI5) app: no OData service, no annotations, the view is built in plain ABAP.

One runnable sample per statement, plus the two business objects to run them against, so nothing else has to be installed.

**Two ways in:**

- **You know EML and want the snippet** → [Find the snippet](#find-the-snippet). Every class carries its statement in the comment at the very top, so you see it the moment you open the file.
- **RAP is new to you** → read [The business object](#the-business-object) first. It is one page, and without it half the messages the samples show will not mean anything.

## Start here

Run [`00 overview`](src/z2ui5_cl_smpe_app_00.clas.abap) — `?app_start=z2ui5_cl_smpe_app_00`. It lists every sample and opens it in a new browser tab, so the overview stays open and several samples can run side by side. *Regenerate Demo Data* in its header fills both business objects.

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

## Setup

1. Install [abap2UI5](https://github.com/abap2UI5/abap2UI5).
2. Pull this repository with [abapGit](https://abapgit.org). ABAP Platform >= 1909 or BTP ABAP Environment — EML needs it, so unlike the other sample repositories this one is not downported to 7.02.
3. Fill the tables: run `Z2UI5_CL_SMPE_DATA_TRV` and `Z2UI5_CL_SMPE_DATA_TRD` with F9 in ADT, or press *Regenerate Demo Data* in the overview (*Generate Demo Data* in a single sample does the same for its own business object). Both offer `data_generate( )`, `data_delete( )` and `data_reset( )`.
4. Start `?app_start=z2ui5_cl_smpe_app_00` and pick a sample from there.

Demo data is created through the business object, not with an `INSERT` — otherwise the determinations would not run and the rows would be data the BO could never produce.

## Structure

```
src/               00 overview, the entry point into all samples
src/00/00          context shared by the samples
src/00/01/01       RAP business object, no draft         Z2UI5_R_SMPE_TRV
src/00/01/02       RAP business object, draft enabled    Z2UI5_R_SMPE_TRD
src/01             samples 01-05 on the business object of 00/01/01
src/02             samples 06-10 on the business object of 00/01/02
```

Every sample app is called `Z2UI5_CL_SMPE_APP_<no>`, so the classes sort in the reading order — in ADT, in abapGit and in the overview. What a sample does is not in its name but in the ABAP Doc at the top of the class and in its title, which is why a sample opened from the overview says *abap2UI5 - EML - 07 Enter Draft Mode*.

Each sample is meant to be read on its own. That is why they repeat each other's view code instead of sharing a helper: you should never have to jump into a utility class to understand one screen.

---

One caveat about the green badges above: abaplint parses EML but does not resolve behavior definitions, so entity, alias and action names inside EML statements are **not** checked, and neither are the `.asbdef` files.
