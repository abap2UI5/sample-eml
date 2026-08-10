"! <p class="shorttext synchronized">abap2UI5 EML sample - demo data (draft)</p>
"! Demo data for the draft enabled business object z2ui5_r_smpe_trd.
"!
"! Run it in ADT with F9 - it is a console application - or press the button
"! in one of the sample apps, which calls the same methods.
"!
"! Writing the tables by hand would hurt here: the draft table
"! z2ui5_d_smpe_trd carries the admin fields of SYCH_BDL_DRAFT_ADMIN_INC.
"! Creating a draft and activating it is both correct and shorter - and it is
"! the lifecycle the samples teach.
CLASS z2ui5_cl_smpe_data_trd DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! Deletes everything, then creates the demo set. This is what F9 runs.
    CLASS-METHODS data_reset
      RETURNING
        VALUE(result) TYPE string.

    "! Creates three demo travels as drafts and activates them, keeping
    "! whatever is already there.
    CLASS-METHODS data_generate
      RETURNING
        VALUE(result) TYPE string.

    "! Discards every draft and deletes every active travel.
    CLASS-METHODS data_delete
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_data_trd IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    out->write( data_reset( ) ).

  ENDMETHOD.


  METHOD data_reset.

    result = |{ data_delete( ) } { data_generate( ) }|.

  ENDMETHOD.


  METHOD data_generate.

    " a new instance of a draft enabled business object is born as a draft
    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        CREATE FIELDS ( agencyid customerid begindate enddate bookingfee currencycode description )
        WITH VALUE #( %is_draft    = if_abap_behv=>mk-on
                      currencycode = 'EUR'
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
      MAPPED DATA(s_mapped)
      FAILED DATA(s_failed).

    IF s_failed-travel IS NOT INITIAL.
      ROLLBACK ENTITIES.
      result = |Demo drafts rejected, { lines( s_failed-travel ) } instance(s) refused.|.
      RETURN.
    ENDIF.

    COMMIT ENTITIES.

    " Activate runs the validations, so anything wrong surfaces here
    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        EXECUTE Activate FROM VALUE #( FOR s_new IN s_mapped-travel
                                       ( %tky = VALUE #( traveluuid = s_new-traveluuid
                                                         %is_draft  = if_abap_behv=>mk-on ) ) )
      FAILED DATA(s_failed_act)
      REPORTED DATA(s_reported_act).

    IF s_failed_act-travel IS NOT INITIAL.
      ROLLBACK ENTITIES.
      result = `The demo drafts were created but refused on activation.`.
      RETURN.
    ENDIF.

    COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trd
      FAILED DATA(s_failed_commit)
      REPORTED DATA(s_reported_commit).

    IF s_failed_commit IS NOT INITIAL.
      result = `Demo data rejected by the business object on commit.`.
      RETURN.
    ENDIF.

    result = `3 demo travels created and activated.`.

  ENDMETHOD.


  METHOD data_delete.

    SELECT FROM z2ui5_r_smpe_trd
      FIELDS TravelUuid
      INTO TABLE @DATA(t_keys).

    IF t_keys IS INITIAL.
      result = `Nothing to delete.`.
      RETURN.
    ENDIF.

    " an active instance may carry a draft, and that draft has to go first -
    " Discard on an instance without a draft simply comes back in FAILED,
    " which is why the response is not evaluated here
    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        EXECUTE Discard FROM VALUE #( FOR s_draft IN t_keys
                                      ( %tky = VALUE #( traveluuid = s_draft-traveluuid
                                                        %is_draft  = if_abap_behv=>mk-on ) ) )
      FAILED DATA(s_failed_discard).

    COMMIT ENTITIES.

    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        DELETE FROM VALUE #( FOR s_key IN t_keys
                             ( %tky = VALUE #( traveluuid = s_key-traveluuid
                                               %is_draft  = if_abap_behv=>mk-off ) ) )
      FAILED DATA(s_failed).

    IF s_failed-travel IS NOT INITIAL.
      ROLLBACK ENTITIES.
      result = `Deletion refused by the business object.`.
      RETURN.
    ENDIF.

    COMMIT ENTITIES.

    result = |{ lines( t_keys ) } travel(s) deleted.|.

  ENDMETHOD.

ENDCLASS.
