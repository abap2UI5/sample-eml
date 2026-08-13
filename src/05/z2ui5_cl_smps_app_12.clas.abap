CLASS z2ui5_cl_smps_app_12 DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_log,
        event_name TYPE z2ui5_e_smps_evt_name,
        log_text   TYPE z2ui5_e_smps_log_text,
        created_by TYPE syuname,
      END OF ty_s_log.
    DATA mt_log TYPE STANDARD TABLE OF ty_s_log WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS data_read.
    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smps_app_12 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.
    me->client = client.
    IF client->check_on_init( ).
      data_read( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      CASE client->get( )-event.
        WHEN `REFRESH`.
          data_read( ).
          view_display( ).
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD data_read.
    SELECT FROM z2ui5_t_smps_log
      FIELDS event_name, log_text, created_by
      ORDER BY created_at DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @mt_log
      UP TO 100 ROWS.
  ENDMETHOD.

  METHOD view_display.
    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    DATA(page) = view->shell(
        )->page(
            title          = `RAP Events Demo - Event Log (abap2UI5)`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( ) ).

    DATA(table) = page->table( client->_bind( mt_log ) ).
    table->header_toolbar(
        )->toolbar(
            )->title( `Business Events`
            )->toolbar_spacer(
            )->button(
                icon  = `sap-icon://refresh`
                press = client->_event( `REFRESH` ) ).

    table->columns(
        )->column( )->text( `Event` )->get_parent(
        )->column( )->text( `Details` )->get_parent(
        )->column( )->text( `User` ).

    table->items( )->column_list_item(
        )->cells(
            )->text( `{EVENT_NAME}`
            )->text( `{LOG_TEXT}`
            )->text( `{CREATED_BY}` ).

    client->view_display( view->stringify( ) ).
  ENDMETHOD.

ENDCLASS.
