# 05 — Business Events

*[← all packages](../../README.md)*

A RAP business object announces what happened, and something else reacts to it.
Packages [`03`](../03/README.md) and [`04`](../04/README.md) end at the save — this
one starts there.

The interesting part for abap2UI5 is the decoupling. The app that creates a ticket
knows nothing about the handler. The handler knows nothing about the UI. Both are
plain ABAP, and both are on screen at the same time: one app triggers the events,
the second shows what arrived. RAP does the wiring in between.

## What you need

ABAP Platform >= 1909 or a BTP ABAP Environment for the EML part — plus a release
that already carries **RAP business events**. They are a younger RAP feature than
EML itself: if `RAISE ENTITY EVENT` does not activate on your system, that package
is simply out of reach for now, and nothing else in this repository is affected.

No service activation, no ICF node. Import, activate, start the app — the ticket
table fills itself as you create tickets.

## The two apps

| App | Role |
|---|---|
| [`zcl_lk22_ui5_ticket`](01/zcl_lk22_ui5_ticket.clas.abap) | create tickets through the BO — every create and update raises an event |
| [`zcl_lk22_ui5_evtlog`](01/zcl_lk22_ui5_evtlog.clas.abap) | the event log the handler writes, newest first |

Start them with `?app_start=zcl_lk22_ui5_ticket` and
`?app_start=zcl_lk22_ui5_evtlog`. Open both in two browser tabs, create a ticket in
the first, press refresh in the second — the log entry the handler wrote is there.

Events are raised in the save sequence and consumed **afterwards**, so the log
entry appears once the transaction is through, not during the roundtrip that
created the ticket. That is what the refresh button is for.

## The two kinds of event

The behavior definition [`zi_lk22_ticket.bdef.asbdef`](01/zi_lk22_ticket.bdef.asbdef)
declares one of each — the distinction is the whole point of the sample:

```abap
" notification event: the key, nothing else
event TicketCreated;

" data event: an enriched payload, typed by an abstract entity
event StatusChanged parameter ZA_LK22_STATUSCHG;
```

A **notification** event says *something happened to this instance* and leaves it to
the consumer to read the current state. A **data** event carries the state along, so
the consumer needs no second read — at the price of shipping data that may already
be stale by the time it is handled. The payload type is an ordinary abstract entity,
[`ZA_LK22_STATUSCHG`](01/za_lk22_statuschg.ddls.asddls).

## Who raises them

The additional save of the behavior pool,
[`zbp_lk22_ticket`](01/zbp_lk22_ticket.clas.locals_imp.abap) — `save_modified` sees
what the transaction changed and raises accordingly:

```abap
" on create - key only
RAISE ENTITY EVENT zi_lk22_ticket~TicketCreated
  FROM VALUE #( FOR c IN create-ticket ( %key = VALUE #( TicketUUID = c-TicketUUID ) ) ).

" on update - key plus payload in %param
RAISE ENTITY EVENT zi_lk22_ticket~StatusChanged
  FROM VALUE #( FOR t IN lt_current (
                  %key   = VALUE #( TicketUUID = t-TicketUUID )
                  %param = VALUE #( Title = t-Title Status = t-Status … ) ) ).
```

## Who listens

A separate class, [`zcl_lk22_evt_handler`](01/zcl_lk22_evt_handler.clas.locals_imp.abap),
inheriting from `CL_ABAP_BEHAVIOR_EVENT_HANDLER`. It subscribes per event, receives
the instances as a table, and writes them into the log:

```abap
METHODS on_ticket_created FOR ENTITY EVENT
  ticketcreated FOR zi_lk22_ticket~TicketCreated.

METHODS on_status_changed FOR ENTITY EVENT
  statuschanged FOR zi_lk22_ticket~StatusChanged.
```

Nothing registers this class anywhere — the `FOR ENTITY EVENT` declaration *is* the
subscription. Add a second handler and it runs too; delete this one and the BO
still works. That is the property worth taking away: consumers come and go without
the business object changing a line.

## What is in the package

| Object | Role |
|---|---|
| `ZLK22_TICKET`, `ZLK22_TICKET_D` | the ticket table and its draft table |
| [`ZI_LK22_TICKET`](01/zi_lk22_ticket.ddls.asddls) + [`.bdef`](01/zi_lk22_ticket.bdef.asbdef) | the root view entity and the behavior with the two events |
| [`ZBP_LK22_TICKET`](01/zbp_lk22_ticket.clas.locals_imp.abap) | behavior pool — determination and the additional save that raises |
| [`ZA_LK22_STATUSCHG`](01/za_lk22_statuschg.ddls.asddls) | the abstract entity typing the data event payload |
| [`ZCL_LK22_EVT_HANDLER`](01/zcl_lk22_evt_handler.clas.locals_imp.abap) | the event handler, writes the log |
| `ZLK22_EVTLOG` + [`ZI_LK22_EVTLOG`](01/zi_lk22_evtlog.ddls.asddls) | the log table and its CDS view |
| [`ZC_LK22_TICKET`](01/zc_lk22_ticket.ddls.asddls), `ZUI_LK22_TICKET`, `ZUI_LK22_TICKET_O4` | projection, service definition and an OData V4 binding |
| [`ZCL_LK22_UI5_TICKET`](01/zcl_lk22_ui5_ticket.clas.abap), [`ZCL_LK22_UI5_EVTLOG`](01/zcl_lk22_ui5_evtlog.clas.abap) | the two abap2UI5 apps |

The projection, service definition and service binding are there on purpose: the
same business object can be published as an OData V4 service and consumed by a
Fiori Elements app, while the abap2UI5 apps sit next to it on the same BO. Use one,
use the other, use both — the business object does not care, and neither does
abap2UI5.

## Two notes on the code

- The objects of this package carry an **`LK22`** token instead of the repository's
  `SMPE` scheme; they came in as a contribution and have not been renamed yet.
  abaplint reports each of them under `object_naming` — see the
  [Namespace](../../README.md#namespace) section.
- `RAISE ENTITY EVENT` and `FOR ENTITY EVENT` are beyond the abaplint parser, so the
  parser errors this package reports are about the linter, not about the code: it
  activates fine in an ABAP system.

## Where to go next

- [`07` AMC/APC](../07/README.md) — the other half of the story: pushing what
  happened into an open browser tab instead of waiting for a refresh.
