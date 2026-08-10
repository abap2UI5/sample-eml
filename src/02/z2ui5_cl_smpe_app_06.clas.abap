CLASS z2ui5_cl_smpe_app_06 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_travel,
        travel_uuid TYPE string,
        travel_id   TYPE string,
        customer_id TYPE string,
        description TYPE string,
        status      TYPE string,
        draft_text  TYPE string,
        draft_state TYPE string,
      END OF ty_s_travel.
    DATA t_travels TYPE STANDARD TABLE OF ty_s_travel WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS data_read.
    METHODS view_display.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_app_06 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      data_read( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      CASE client->get( )-event.
        WHEN `REFRESH`.
          data_read( ).
          client->view_model_update( ).
        WHEN `GENERATE`.
          client->message_toast_display( z2ui5_cl_smpe_data_trd=>data_reset( ) ).
          data_read( ).
          client->view_model_update( ).
      ENDCASE.
    ENDIF.

  ENDMETHOD.


  METHOD data_read.

    " the CDS view returns the active instances - a draft is not in there
    SELECT FROM z2ui5_r_smpe_trd
      FIELDS TravelUuid,
             TravelId,
             CustomerId,
             Description,
             OverallStatus
      ORDER BY TravelId
      INTO TABLE @DATA(t_result)
      UP TO 20 ROWS.

    " A draft shares the key of its active instance - only %is_draft tells
    " the two apart. So reading the keys with %is_draft = on answers the
    " question "which travels have a draft?": every key that comes back in
    " RESULT has one, everything else lands in FAILED. That is the whole
    " trick, and every other draft sample of this repository relies on it.
    READ ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        FIELDS ( travelid ) WITH VALUE #( FOR s_row IN t_result
                                          ( %tky = VALUE #( traveluuid = s_row-traveluuid
                                                            %is_draft  = if_abap_behv=>mk-on ) ) )
      RESULT DATA(t_drafts)
      FAILED DATA(s_failed).

    t_travels = VALUE #( FOR s_result IN t_result
        ( travel_uuid = |{ s_result-traveluuid }|
          travel_id   = |{ s_result-travelid ALPHA = OUT }|
          customer_id = |{ s_result-customerid ALPHA = OUT }|
          description = |{ s_result-description }|
          status      = z2ui5_cl_smpe_context=>status_get_text( s_result-overallstatus )
          draft_text  = COND #( WHEN line_exists( t_drafts[ KEY entity traveluuid = s_result-traveluuid ] )
                                THEN `Draft` ELSE `-` )
          draft_state = COND #( WHEN line_exists( t_drafts[ KEY entity traveluuid = s_result-traveluuid ] )
                                THEN `Warning` ELSE `None` ) ) ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    DATA(table) = view->shell(
        )->page(
            title          = `abap2UI5 - EML - 06 Which Travels Have a Draft?`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( )
            )->table( client->_bind( t_travels ) ).

    table->header_toolbar( )->toolbar(
        )->title( `READ ENTITIES ... WITH %is_draft = mk-on`
        )->toolbar_spacer(
        )->button(
            text  = `Generate Demo Data`
            press = client->_event( `GENERATE` )
        )->button(
            icon  = `sap-icon://refresh`
            press = client->_event( `REFRESH` ) ).

    table->columns(
        )->column( )->text( `ID` )->get_parent(
        )->column( )->text( `Customer` )->get_parent(
        )->column( )->text( `Description` )->get_parent(
        )->column( )->text( `Status` )->get_parent(
        )->column( )->text( `Draft` ).

    table->items( )->column_list_item(
        )->cells(
            )->text( `{TRAVEL_ID}`
            )->text( `{CUSTOMER_ID}`
            )->text( `{DESCRIPTION}`
            )->text( `{STATUS}`
            )->object_status(
                text  = `{DRAFT_TEXT}`
                state = `{DRAFT_STATE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
