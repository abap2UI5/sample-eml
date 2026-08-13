"! <p class="shorttext synchronized">abap2UI5 - EML sample 03 - update travel</p>
"! Changes single fields of one instance. UPDATE FIELDS names what may be
"! written, everything else stays untouched.
"!
"!     MODIFY ENTITIES OF z2ui5_r_smps_trv
"!       ENTITY travel
"!         UPDATE FIELDS ( description )
"!         WITH VALUE #( ( travelid    = travel_id
"!                         description = s_travel-description ) )
"!       FAILED DATA(s_failed)
"!       REPORTED DATA(s_reported).
"!
"! Worth knowing: fields the behavior definition marks readonly are refused.
"! TotalPrice and OverallStatus belong to the business object, not to the
"! caller - try it and read what comes back in REPORTED.
CLASS z2ui5_cl_smps_app_03 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_travel,
        travel_id   TYPE string,
        customer_id TYPE string,
        description TYPE string,
      END OF ty_s_travel.
    DATA t_travels TYPE STANDARD TABLE OF ty_s_travel WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS data_read.
    METHODS data_update.
    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smps_app_03 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      data_read( ).
      view_display( ).
    ELSEIF client->check_on_event( `UPDATE` ).
      data_update( ).
    ENDIF.

  ENDMETHOD.


  METHOD data_read.

    " a plain SELECT on the CDS view - reading does not need EML, the list
    " is only here so there is something to change
    SELECT FROM z2ui5_r_smps_trv
      FIELDS TravelId,
             CustomerId,
             Description
      ORDER BY TravelId
      INTO TABLE @DATA(t_result)
      UP TO 20 ROWS.

    t_travels = VALUE #( FOR s_result IN t_result
        ( travel_id   = |{ s_result-travelid ALPHA = OUT }|
          customer_id = |{ s_result-customerid ALPHA = OUT }|
          description = |{ s_result-description }| ) ).

  ENDMETHOD.


  METHOD data_update.

    DATA(travel_id) = client->get_event_arg( 1 ).
    DATA(s_travel) = t_travels[ travel_id = travel_id ].

    " UPDATE FIELDS names exactly the fields that are changed - everything
    " else on the instance stays untouched, which is why no read is needed
    " before the change
    MODIFY ENTITIES OF z2ui5_r_smps_trv
      ENTITY travel
        UPDATE FIELDS ( description )
        WITH VALUE #( ( travelid    = travel_id
                        description = s_travel-description ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      z2ui5_cl_smps_context=>msg_display( client = client val = s_reported-travel ).
      RETURN.

    ENDIF.

    COMMIT ENTITIES RESPONSE OF z2ui5_r_smps_trv
      FAILED DATA(s_failed_commit)
      REPORTED DATA(s_reported_commit).

    IF s_failed_commit IS NOT INITIAL.

      z2ui5_cl_smps_context=>msg_display( client = client val = s_reported_commit-travel ).
      RETURN.

    ENDIF.

    data_read( ).
    client->view_model_update( ).
    client->message_toast_display( |Travel { travel_id } updated| ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    DATA(table) = view->shell(
        )->page(
            title          = `abap2UI5 - EML - 03 Update Travel`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( )
            )->table( client->_bind( t_travels ) ).

    table->header_toolbar( )->toolbar(
        )->title( `MODIFY ENTITIES OF Z2UI5_R_SMPS_TRV ... UPDATE` ).

    table->columns(
        )->column( )->text( `ID` )->get_parent(
        )->column( )->text( `Customer` )->get_parent(
        )->column( )->text( `Description` )->get_parent(
        )->column( )->text( `` ).

    table->items( )->column_list_item(
        )->cells(
            )->text( `{TRAVEL_ID}`
            )->text( `{CUSTOMER_ID}`
            )->input( `{DESCRIPTION}`
            )->button(
                text  = `Update`
                press = client->_event( val   = `UPDATE`
                                        t_arg = VALUE #( ( `${TRAVEL_ID}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
