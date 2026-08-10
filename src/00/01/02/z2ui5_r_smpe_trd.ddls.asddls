@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'abap2UI5 EML sample - travel (draft)'
@Metadata.ignorePropagatedAnnotations: true
define root view entity z2ui5_r_smpe_trd
  as select from z2ui5_t_smpe_trd
{
      // the key of a draft enabled business object is a UUID: the draft and
      // the active instance share it, only %is_draft tells them apart
  key travel_uuid                          as TravelUuid,

      travel_id                            as TravelId,
      agency_id                            as AgencyId,
      customer_id                          as CustomerId,
      begin_date                           as BeginDate,
      end_date                             as EndDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee                          as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price                          as TotalPrice,
      @Semantics.currencyCode: true
      currency_code                        as CurrencyCode,

      description                          as Description,
      overall_status                       as OverallStatus,

      @Semantics.user.createdBy: true
      created_by                           as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                           as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                      as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                      as LastChangedAt
}
