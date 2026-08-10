CLASS z2ui5_cl_smpe_04_delete DEFINITION PUBLIC.

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
    METHODS data_delete.
    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_04_delete IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      data_read( ).
      view_display( ).
    ELSEIF client->check_on_event( `DELETE` ).
      data_delete( ).
    ENDIF.

  ENDMETHOD.


  METHOD data_read.

    SELECT FROM z2ui5_r_smpe_trv
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


  METHOD data_delete.

    DATA(travel_id) = client->get_event_arg( 1 ).

    " DELETE only needs the key - and it can still fail, e.g. when the
    " business object refuses the deletion or the instance is locked
    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        DELETE FROM VALUE #( ( travelid = travel_id ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported-travel ).
      RETURN.

    ENDIF.

    COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trv
      FAILED DATA(s_failed_commit)
      REPORTED DATA(s_reported_commit).

    IF s_failed_commit IS NOT INITIAL.

      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported_commit-travel ).
      RETURN.

    ENDIF.

    data_read( ).
    client->view_model_update( ).
    client->message_toast_display( |Travel { travel_id } deleted| ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    DATA(table) = view->shell(
        )->page(
            title          = `abap2UI5 - EML - 04 Delete Travel`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( )
            )->table( client->_bind( t_travels ) ).

    table->header_toolbar( )->toolbar(
        )->title( `MODIFY ENTITIES OF Z2UI5_R_SMPE_TRV ... DELETE` ).

    table->columns(
        )->column( )->text( `ID` )->get_parent(
        )->column( )->text( `Customer` )->get_parent(
        )->column( )->text( `Description` )->get_parent(
        )->column( )->text( `` ).

    table->items( )->column_list_item(
        )->cells(
            )->text( `{TRAVEL_ID}`
            )->text( `{CUSTOMER_ID}`
            )->text( `{DESCRIPTION}`
            )->button(
                text  = `Delete`
                icon  = `sap-icon://delete`
                press = client->_event( val   = `DELETE`
                                        t_arg = VALUE #( ( `${TRAVEL_ID}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
