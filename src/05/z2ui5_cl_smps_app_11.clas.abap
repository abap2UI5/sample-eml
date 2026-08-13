CLASS z2ui5_cl_smps_app_11 DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_ticket,
        title      TYPE z2ui5_e_smps_title,
        priority   TYPE z2ui5_e_smps_priority,
        status     TYPE z2ui5_e_smps_status,
        created_by TYPE syuname,
      END OF ty_s_ticket.
    DATA mt_tickets TYPE STANDARD TABLE OF ty_s_ticket WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_create,
        title    TYPE string,
        priority TYPE string,
        status   TYPE string,
      END OF ty_s_create.
    DATA ms_create TYPE ty_s_create.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS on_init.
    METHODS on_event.
    METHODS on_event_create.
    METHODS data_read.
    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smps_app_11 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.
    me->client = client.
    IF client->check_on_init( ).
      ms_create = VALUE #( priority = `M` status = `NEW` ).
      on_init( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.
  ENDMETHOD.

  METHOD on_init.
    data_read( ).
    view_display( ).
  ENDMETHOD.

  METHOD on_event.
    CASE client->get( )-event.
      WHEN `CREATE`.
        on_event_create( ).
      WHEN `REFRESH`.
        data_read( ).
        view_display( ).
    ENDCASE.
  ENDMETHOD.

  METHOD on_event_create.
    IF ms_create-title IS INITIAL.
      client->message_toast_display( `Please enter a title` ).
      RETURN.
    ENDIF.

    " Create a ticket via the RAP business object -> raises the RAP business event
    MODIFY ENTITIES OF z2ui5_r_smps_tck
      ENTITY Ticket
        CREATE FIELDS ( title priority status )
        WITH VALUE #( ( %cid     = `CID_TICKET`
                        title    = ms_create-title
                        priority = ms_create-priority
                        status   = ms_create-status ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed)
      REPORTED DATA(reported).

    IF failed-ticket IS NOT INITIAL.
      ROLLBACK ENTITIES.
      client->message_toast_display( `Create failed` ).
      RETURN.
    ENDIF.

    COMMIT ENTITIES RESPONSE OF z2ui5_r_smps_tck
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    IF commit_failed IS INITIAL.
      client->message_toast_display( |Ticket '{ ms_create-title }' created - business event fired| ).
      ms_create = VALUE #( priority = `M` status = `NEW` ).
      data_read( ).
      view_display( ).
    ELSE.
      client->message_toast_display( `Save failed` ).
    ENDIF.
  ENDMETHOD.

  METHOD data_read.
    SELECT FROM z2ui5_t_smps_tck
      FIELDS title, priority, status, created_by
      ORDER BY created_at DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @mt_tickets
      UP TO 50 ROWS.
  ENDMETHOD.

  METHOD view_display.
    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    DATA(page) = view->shell(
        )->page(
            title          = `RAP Events Demo - Tickets (abap2UI5)`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( ) ).

    " --- create form ---
    page->simple_form( editable = abap_true
        )->content( `form`
        )->label( `Title`
        )->input( client->_bind( ms_create-title )
        )->label( `Priority (H / M / L)`
        )->input( client->_bind( ms_create-priority )
        )->label( `Status`
        )->input( client->_bind( ms_create-status )
        )->button(
            text  = `Create Ticket`
            press = client->_event( `CREATE` )
            type  = `Emphasized` ).

    " --- tickets table ---
    DATA(table) = page->table( client->_bind( mt_tickets ) ).
    table->header_toolbar(
        )->toolbar(
            )->title( `Tickets`
            )->toolbar_spacer(
            )->button(
                icon  = `sap-icon://refresh`
                press = client->_event( `REFRESH` ) ).

    table->columns(
        )->column( )->text( `Title` )->get_parent(
        )->column( )->text( `Priority` )->get_parent(
        )->column( )->text( `Status` )->get_parent(
        )->column( )->text( `Created By` ).

    table->items( )->column_list_item(
        )->cells(
            )->text( `{TITLE}`
            )->text( `{PRIORITY}`
            )->text( `{STATUS}`
            )->text( `{CREATED_BY}` ).

    client->view_display( view->stringify( ) ).
  ENDMETHOD.

ENDCLASS.
