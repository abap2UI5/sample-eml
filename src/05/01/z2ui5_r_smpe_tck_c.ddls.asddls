@EndUserText.label: 'RAP Events Demo - Ticket'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@UI.headerInfo: { typeName: 'Ticket',
                  typeNamePlural: 'Tickets',
                  title: { type: #STANDARD, value: 'Title' },
                  description: { type: #STANDARD, value: 'Status' } }
define root view entity Z2UI5_R_SMPE_TCK_C
  provider contract transactional_query
  as projection on Z2UI5_R_SMPE_TCK
{
      @UI.facet: [ { id:       'GeneralInfo',
                     purpose:  #STANDARD,
                     type:     #IDENTIFICATION_REFERENCE,
                     label:    'Ticket Details',
                     position: 10 } ]
  key TicketUUID,

      @UI: { lineItem:       [ { position: 10, label: 'Title' } ],
             identification: [ { position: 10, label: 'Title' } ],
             selectionField: [ { position: 10 } ] }
      Title,

      @UI: { lineItem:       [ { position: 20, label: 'Priority' } ],
             identification: [ { position: 20, label: 'Priority' } ],
             selectionField: [ { position: 20 } ] }
      Priority,

      @UI: { lineItem:       [ { position: 30, label: 'Status' } ],
             identification: [ { position: 30, label: 'Status' } ],
             selectionField: [ { position: 30 } ] }
      Status,

      @UI: { lineItem:       [ { position: 40, label: 'Created By' } ],
             identification: [ { position: 40, label: 'Created By' } ] }
      CreatedBy,

      @UI: { lineItem:       [ { position: 50, label: 'Created At' } ],
             identification: [ { position: 50, label: 'Created At' } ] }
      CreatedAt,

      @UI.hidden: true
      ChangedBy,

      @UI.hidden: true
      LastChangedAt,

      @UI.hidden: true
      LocalLastChangedAt
}
