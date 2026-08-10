"! <p class="shorttext synchronized">abap2UI5 EML sample - demo data</p>
"! Demo data for the business object z2ui5_r_smpe_trv.
"!
"! Two ways to run it, both ending in the same method:
"! <ul>
"! <li>in ADT, press F9 on this class - it is a console application</li>
"! <li>from the abap2UI5 apps, which call reset( ) behind their button</li>
"! </ul>
"!
"! The data is created through the business object with EML, never by an
"! INSERT into z2ui5_t_smpe_trv. An INSERT would skip the determination
"! setInitialValues, so the rows would carry no status and no total price -
"! data this business object could never have produced itself.
CLASS z2ui5_cl_smpe_data_trv DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! Deletes every travel and creates the demo set again.
    "! Deleting first is what makes the keys predictable: early numbering
    "! continues behind MAX( travel_id ), so on an empty table the demo
    "! travels always come out as 1, 2, 3.
    "! @parameter result | one line describing what happened
    CLASS-METHODS reset
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS delete_all
      RETURNING
        VALUE(result) TYPE i.

ENDCLASS.


CLASS z2ui5_cl_smpe_data_trv IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    out->write( reset( ) ).

  ENDMETHOD.


  METHOD reset.

    DATA(deleted) = delete_all( ).

    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        CREATE FIELDS ( agencyid customerid begindate enddate bookingfee currencycode description )
        WITH VALUE #( currencycode = 'EUR'
                      ( %cid        = `DEMO_1`
                        agencyid    = '070001'
                        customerid  = '000001'
                        begindate   = sy-datum
                        enddate     = sy-datum + 14
                        bookingfee  = '20.00'
                        description = 'Demo travel - sightseeing' )
                      ( %cid        = `DEMO_2`
                        agencyid    = '070002'
                        customerid  = '000002'
                        begindate   = sy-datum + 30
                        enddate     = sy-datum + 37
                        bookingfee  = '35.50'
                        description = 'Demo travel - business trip' )
                      ( %cid        = `DEMO_3`
                        agencyid    = '070003'
                        customerid  = '000003'
                        begindate   = sy-datum + 60
                        enddate     = sy-datum + 74
                        bookingfee  = '12.75'
                        description = 'Demo travel - city break' ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      result = |Demo data could not be created, { lines( s_failed-travel ) } instance(s) rejected|.
      RETURN.

    ENDIF.

    COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trv
      FAILED DATA(s_failed_commit)
      REPORTED DATA(s_reported_commit).

    IF s_failed_commit IS NOT INITIAL.

      result = `Demo data was rejected by the business object on commit`.
      RETURN.

    ENDIF.

    result = |{ deleted } travel(s) deleted, 3 demo travels created|.

  ENDMETHOD.


  METHOD delete_all.

    SELECT FROM z2ui5_r_smpe_trv
      FIELDS TravelId
      INTO TABLE @DATA(t_keys).

    result = lines( t_keys ).
    IF t_keys IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        DELETE FROM VALUE #( FOR s_key IN t_keys ( travelid = s_key-travelid ) )
      FAILED DATA(s_failed).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      result = 0.
      RETURN.

    ENDIF.

    COMMIT ENTITIES.

  ENDMETHOD.

ENDCLASS.
