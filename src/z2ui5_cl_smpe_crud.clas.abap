CLASS z2ui5_cl_smpe_crud DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_travel,
        travel_id      TYPE string,
        customer_id    TYPE string,
        begin_date     TYPE string,
        end_date       TYPE string,
        total_price    TYPE string,
        overall_status TYPE string,
        status_state   TYPE string,
        description    TYPE string,
      END OF ty_s_travel.
    DATA t_travels TYPE STANDARD TABLE OF ty_s_travel WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_create,
        agency_id   TYPE string,
        customer_id TYPE string,
        begin_date  TYPE string,
        end_date    TYPE string,
        booking_fee TYPE string,
        currency    TYPE string,
        description TYPE string,
      END OF ty_s_create.
    DATA s_create TYPE ty_s_create.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS on_init.
    METHODS on_event.
    METHODS on_event_create.
    METHODS on_event_save.
    METHODS on_event_accept.
    METHODS on_event_reject.
    METHODS on_event_delete.
    METHODS view_display.
    METHODS popup_create_display.
    METHODS data_read.

    METHODS data_save
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS messages_display
      IMPORTING
        t_reported TYPE ANY TABLE.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_crud IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
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
      WHEN `REFRESH`.
        data_read( ).
        client->view_model_update( ).
      WHEN `CREATE`.
        s_create = VALUE #( currency = `EUR` ).
        popup_create_display( ).
      WHEN `POPUP_CREATE_CONFIRM`.
        on_event_create( ).
      WHEN `POPUP_CREATE_CANCEL`.
        client->popup_destroy( ).
      WHEN `SAVE`.
        on_event_save( ).
      WHEN `ACCEPT`.
        on_event_accept( ).
      WHEN `REJECT`.
        on_event_reject( ).
      WHEN `DELETE`.
        on_event_delete( ).
    ENDCASE.

  ENDMETHOD.


  METHOD on_event_create.

    MODIFY ENTITIES OF /dmo/i_travel_m
      ENTITY travel
        CREATE FIELDS ( agency_id customer_id begin_date end_date booking_fee currency_code description overall_status )
        WITH VALUE #( ( %cid           = `CREATE_TRAVEL_1`
                        agency_id      = s_create-agency_id
                        customer_id    = s_create-customer_id
                        begin_date     = s_create-begin_date
                        end_date       = s_create-end_date
                        booking_fee    = s_create-booking_fee
                        currency_code  = s_create-currency
                        description    = s_create-description
                        overall_status = `O` ) )
      MAPPED DATA(s_mapped)
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      messages_display( s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      client->popup_destroy( ).
      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( |Travel { s_mapped-travel[ 1 ]-travel_id ALPHA = OUT } created| ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_save.

    DATA(travel_id) = client->get_event_arg( 1 ).
    DATA(s_travel) = t_travels[ travel_id = travel_id ].

    MODIFY ENTITIES OF /dmo/i_travel_m
      ENTITY travel
        UPDATE FIELDS ( description )
        WITH VALUE #( ( travel_id   = travel_id
                        description = s_travel-description ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      messages_display( s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( |Travel { travel_id } updated| ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_accept.

    DATA(travel_id) = client->get_event_arg( 1 ).

    MODIFY ENTITIES OF /dmo/i_travel_m
      ENTITY travel
        EXECUTE acceptTravel FROM VALUE #( ( travel_id = travel_id ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      messages_display( s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( |Travel { travel_id } accepted| ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_reject.

    DATA(travel_id) = client->get_event_arg( 1 ).

    MODIFY ENTITIES OF /dmo/i_travel_m
      ENTITY travel
        EXECUTE rejectTravel FROM VALUE #( ( travel_id = travel_id ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      messages_display( s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( |Travel { travel_id } rejected| ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_delete.

    DATA(travel_id) = client->get_event_arg( 1 ).

    MODIFY ENTITIES OF /dmo/i_travel_m
      ENTITY travel
        DELETE FROM VALUE #( ( travel_id = travel_id ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      messages_display( s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( |Travel { travel_id } deleted| ).

    ENDIF.

  ENDMETHOD.


  METHOD data_read.

    SELECT FROM /dmo/i_travel_m
      FIELDS travel_id,
             customer_id,
             begin_date,
             end_date,
             total_price,
             currency_code,
             overall_status,
             description
      ORDER BY travel_id DESCENDING
      INTO TABLE @DATA(t_result)
      UP TO 20 ROWS.

    t_travels = VALUE #( FOR s_result IN t_result
        ( travel_id      = |{ s_result-travel_id ALPHA = OUT }|
          customer_id    = |{ s_result-customer_id ALPHA = OUT }|
          begin_date     = |{ s_result-begin_date DATE = ISO }|
          end_date       = |{ s_result-end_date DATE = ISO }|
          total_price    = |{ s_result-total_price } { s_result-currency_code }|
          overall_status = SWITCH #( s_result-overall_status
                                     WHEN `O` THEN `Open`
                                     WHEN `A` THEN `Accepted`
                                     WHEN `X` THEN `Rejected` )
          status_state   = SWITCH #( s_result-overall_status
                                     WHEN `O` THEN `Information`
                                     WHEN `A` THEN `Success`
                                     WHEN `X` THEN `Error` )
          description    = |{ s_result-description }| ) ).

  ENDMETHOD.


  METHOD data_save.

    COMMIT ENTITIES RESPONSE OF /dmo/i_travel_m
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed IS INITIAL.
      result = abap_true.

    ELSE.
      messages_display( s_reported-travel ).
    ENDIF.

  ENDMETHOD.


  METHOD messages_display.

    DATA message TYPE REF TO if_message.
    DATA text TYPE string.

    LOOP AT t_reported ASSIGNING FIELD-SYMBOL(<s_reported>).

      ASSIGN COMPONENT `%msg` OF STRUCTURE <s_reported> TO FIELD-SYMBOL(<message>).
      IF sy-subrc = 0 AND <message> IS BOUND.
        message ?= <message>.
        text = |{ text }{ message->get_text( ) } |.
      ENDIF.

    ENDLOOP.

    IF text IS INITIAL.
      text = `The operation failed, no further details available`.
    ENDIF.

    client->message_box_display(
        text = text
        type = `error` ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    DATA(page) = view->shell(
        )->page(
            title          = `abap2UI5 - EML - Manage Travels`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( ) ).

    DATA(table) = page->table( client->_bind_edit( t_travels ) ).
    table->header_toolbar(
        )->toolbar(
            )->title( `Travels (/DMO/I_TRAVEL_M)`
            )->toolbar_spacer(
            )->button(
                text  = `Create`
                icon  = `sap-icon://add`
                press = client->_event( `CREATE` )
                type  = `Emphasized`
            )->button(
                icon  = `sap-icon://refresh`
                press = client->_event( `REFRESH` ) ).

    table->columns(
        )->column( )->text( `ID` )->get_parent(
        )->column( )->text( `Customer` )->get_parent(
        )->column( )->text( `Begin Date` )->get_parent(
        )->column( )->text( `End Date` )->get_parent(
        )->column( )->text( `Total Price` )->get_parent(
        )->column( )->text( `Status` )->get_parent(
        )->column( )->text( `Description` )->get_parent(
        )->column( )->text( `Actions` ).

    table->items( )->column_list_item(
        )->cells(
            )->text( `{TRAVEL_ID}`
            )->text( `{CUSTOMER_ID}`
            )->text( `{BEGIN_DATE}`
            )->text( `{END_DATE}`
            )->text( `{TOTAL_PRICE}`
            )->object_status(
                text  = `{OVERALL_STATUS}`
                state = `{STATUS_STATE}`
            )->input( `{DESCRIPTION}`
            )->hbox(
                )->button(
                    icon    = `sap-icon://save`
                    tooltip = `Save Description`
                    press   = client->_event( val = `SAVE` t_arg = VALUE #( ( `${TRAVEL_ID}` ) ) )
                )->button(
                    icon    = `sap-icon://accept`
                    tooltip = `Accept Travel`
                    press   = client->_event( val = `ACCEPT` t_arg = VALUE #( ( `${TRAVEL_ID}` ) ) )
                )->button(
                    icon    = `sap-icon://decline`
                    tooltip = `Reject Travel`
                    press   = client->_event( val = `REJECT` t_arg = VALUE #( ( `${TRAVEL_ID}` ) ) )
                )->button(
                    icon    = `sap-icon://delete`
                    tooltip = `Delete Travel`
                    press   = client->_event( val = `DELETE` t_arg = VALUE #( ( `${TRAVEL_ID}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD popup_create_display.

    DATA(popup) = z2ui5_cl_xml_view=>factory_popup( ).
    DATA(dialog) = popup->dialog(
        title        = `Create Travel`
        contentwidth = `30rem` ).

    dialog->simple_form( editable = abap_true
        )->content( `form`
        )->label( `Agency ID`
        )->input(
            value       = client->_bind_edit( s_create-agency_id )
            placeholder = `e.g. 70001`
        )->label( `Customer ID`
        )->input(
            value       = client->_bind_edit( s_create-customer_id )
            placeholder = `e.g. 1`
        )->label( `Begin Date`
        )->date_picker(
            value       = client->_bind_edit( s_create-begin_date )
            valueformat = `yyyyMMdd`
        )->label( `End Date`
        )->date_picker(
            value       = client->_bind_edit( s_create-end_date )
            valueformat = `yyyyMMdd`
        )->label( `Booking Fee`
        )->input(
            value       = client->_bind_edit( s_create-booking_fee )
            placeholder = `e.g. 10.50`
        )->label( `Currency`
        )->input( client->_bind_edit( s_create-currency )
        )->label( `Description`
        )->input( client->_bind_edit( s_create-description ) ).

    dialog->begin_button( )->button(
        text  = `Create`
        press = client->_event( `POPUP_CREATE_CONFIRM` )
        type  = `Emphasized` ).
    dialog->end_button( )->button(
        text  = `Cancel`
        press = client->_event( `POPUP_CREATE_CANCEL` ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
