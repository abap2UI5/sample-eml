@EndUserText.label: 'RAP Events Demo - Ticket (Interface)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity Z2UI5_R_SMPS_TCK
  as select from z2ui5_t_smps_tck
{
  key ticket_uuid          as TicketUUID,
      title                as Title,
      priority             as Priority,
      status               as Status,
      @Semantics.user.createdBy: true
      created_by           as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at           as CreatedAt,
      @Semantics.user.lastChangedBy: true
      changed_by           as ChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at      as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
