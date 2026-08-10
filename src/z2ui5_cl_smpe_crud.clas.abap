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
    METHODS on_event_generate.
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
      WHEN `GENERATE`.
        on_event_generate( ).
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


  METHOD on_event_generate.

    " There is no external demo data generator any more - the business object
    " of this repository is filled through its own behavior, with the same
    " EML CREATE the popup above uses. Early numbering assigns the keys.
    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        CREATE FIELDS ( agencyid customerid begindate enddate bookingfee currencycode description )
        WITH VALUE #( ( %cid         = `DEMO_1`
                        agencyid     = '070001'
                        customerid   = '000001'
                        begindate    = sy-datum
                        enddate      = sy-datum + 14
                        bookingfee   = '20.00'
                        currencycode = 'EUR'
                        description  = 'Demo travel - sightseeing' )
                      ( %cid         = `DEMO_2`
                        agencyid     = '070002'
                        customerid   = '000002'
                        begindate    = sy-datum + 30
                        enddate      = sy-datum + 37
                        bookingfee   = '35.50'
                        currencycode = 'EUR'
                        description  = 'Demo travel - business trip' )
                      ( %cid         = `DEMO_3`
                        agencyid     = '070003'
                        customerid   = '000003'
                        begindate    = sy-datum + 60
                        enddate      = sy-datum + 74
                        bookingfee   = '12.75'
                        currencycode = 'EUR'
                        description  = 'Demo travel - city break' ) )
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
      client->message_toast_display( `Demo travels created` ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_create.

    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        CREATE FIELDS ( agencyid customerid begindate enddate bookingfee currencycode description )
        WITH VALUE #( ( %cid         = `CREATE_TRAVEL_1`
                        agencyid     = s_create-agency_id
                        customerid   = s_create-customer_id
                        begindate    = s_create-begin_date
                        enddate      = s_create-end_date
                        bookingfee   = s_create-booking_fee
                        currencycode = s_create-currency
                        description  = s_create-description ) )
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
      client->message_toast_display( |Travel { s_mapped-travel[ 1 ]-travelid ALPHA = OUT } created| ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_save.

    DATA(travel_id) = client->get_event_arg( 1 ).
    DATA(s_travel) = t_travels[ travel_id = travel_id ].

    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        UPDATE FIELDS ( description )
        WITH VALUE #( ( travelid    = travel_id
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

    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        EXECUTE acceptTravel FROM VALUE #( ( travelid = travel_id ) )
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

    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        EXECUTE rejectTravel FROM VALUE #( ( travelid = travel_id ) )
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

    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        DELETE FROM VALUE #( ( travelid = travel_id ) )
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

    SELECT FROM z2ui5_r_smpe_trv
      FIELDS TravelId,
             CustomerId,
             BeginDate,
             EndDate,
             TotalPrice,
             CurrencyCode,
             OverallStatus,
             Description
      ORDER BY TravelId DESCENDING
      INTO TABLE @DATA(t_result)
      UP TO 20 ROWS.

    t_travels = VALUE #( FOR s_result IN t_result
        ( travel_id      = |{ s_result-travelid ALPHA = OUT }|
          customer_id    = |{ s_result-customerid ALPHA = OUT }|
          begin_date     = |{ s_result-begindate DATE = ISO }|
          end_date       = |{ s_result-enddate DATE = ISO }|
          total_price    = |{ s_result-totalprice } { s_result-currencycode }|
          overall_status = SWITCH #( s_result-overallstatus
                                     WHEN `O` THEN `Open`
                                     WHEN `A` THEN `Accepted`
                                     WHEN `X` THEN `Rejected` )
          status_state   = SWITCH #( s_result-overallstatus
                                     WHEN `O` THEN `Information`
                                     WHEN `A` THEN `Success`
                                     WHEN `X` THEN `Error` )
          description    = |{ s_result-description }| ) ).

  ENDMETHOD.


  METHOD data_save.

    COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trv
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

    DATA(table) = page->table( client->_bind( t_travels ) ).
    table->header_toolbar(
        )->toolbar(
            )->title( `Travels (Z2UI5_R_SMPE_TRV)`
            )->toolbar_spacer(
            )->button(
                text  = `Create`
                icon  = `sap-icon://add`
                press = client->_event( `CREATE` )
                type  = `Emphasized`
            )->button(
                text  = `Generate Demo Data`
                press = client->_event( `GENERATE` )
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
            value       = client->_bind( s_create-agency_id )
            placeholder = `e.g. 70001`
        )->label( `Customer ID`
        )->input(
            value       = client->_bind( s_create-customer_id )
            placeholder = `e.g. 1`
        )->label( `Begin Date`
        )->date_picker(
            value       = client->_bind( s_create-begin_date )
            valueformat = `yyyyMMdd`
        )->label( `End Date`
        )->date_picker(
            value       = client->_bind( s_create-end_date )
            valueformat = `yyyyMMdd`
        )->label( `Booking Fee`
        )->input(
            value       = client->_bind( s_create-booking_fee )
            placeholder = `e.g. 10.50`
        )->label( `Currency`
        )->input( client->_bind( s_create-currency )
        )->label( `Description`
        )->input( client->_bind( s_create-description ) ).

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
