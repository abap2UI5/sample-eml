@EndUserText.label: 'RAP Events Demo - Event Log'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@UI.headerInfo: { typeName: 'Event',
                  typeNamePlural: 'Event Log',
                  title: { type: #STANDARD, value: 'EventName' } }
define root view entity Z2UI5_R_SMPE_LOG
  as select from z2ui5_t_smpe_log
{
      @UI.facet: [ { id:       'EventInfo',
                     purpose:  #STANDARD,
                     type:     #IDENTIFICATION_REFERENCE,
                     label:    'Event Details',
                     position: 10 } ]
  key log_uuid       as LogUUID,

      @UI: { lineItem:       [ { position: 10, label: 'Event' } ],
             identification: [ { position: 10, label: 'Event' } ],
             selectionField: [ { position: 10 } ] }
      event_name     as EventName,

      @UI: { lineItem:       [ { position: 20, label: 'Details' } ],
             identification: [ { position: 20, label: 'Details' } ] }
      log_text       as LogText,

      @UI: { lineItem:       [ { position: 30, label: 'User' } ],
             identification: [ { position: 30, label: 'User' } ] }
      @Semantics.user.createdBy: true
      created_by     as CreatedBy,

      @UI: { lineItem:       [ { position: 40, label: 'Time' } ],
             identification: [ { position: 40, label: 'Time' } ] }
      @Semantics.systemDateTime.createdAt: true
      created_at     as CreatedAt,

      @UI: { identification: [ { position: 50, label: 'Ticket UUID' } ] }
      ticket_uuid    as TicketUUID
}
