CLASS z2ui5_cl_smpe_10_draft DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_travel,
        travel_uuid    TYPE string,
        travel_id      TYPE string,
        customer_id    TYPE string,
        begin_date     TYPE string,
        end_date       TYPE string,
        total_price    TYPE string,
        overall_status TYPE string,
        status_state   TYPE string,
        draft_text     TYPE string,
        has_draft      TYPE abap_bool,
      END OF ty_s_travel.
    DATA t_travels TYPE STANDARD TABLE OF ty_s_travel WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_draft,
        travel_uuid TYPE string,
        travel_id   TYPE string,
        agency_id   TYPE string,
        customer_id TYPE string,
        begin_date  TYPE string,
        end_date    TYPE string,
        booking_fee TYPE string,
        currency    TYPE string,
        description TYPE string,
      END OF ty_s_draft.
    DATA s_draft TYPE ty_s_draft.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS on_init.
    METHODS on_event.
    METHODS on_event_generate.
    METHODS on_event_edit.
    METHODS on_event_save_draft.
    METHODS on_event_activate.
    METHODS on_event_discard.
    METHODS view_display.
    METHODS popup_edit_display.
    METHODS data_read.

    METHODS draft_read
      IMPORTING
        uuid TYPE string.

    METHODS data_save
      RETURNING
        VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_10_draft IMPLEMENTATION.

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
      WHEN `EDIT`.
        on_event_edit( ).
      WHEN `SAVE_DRAFT`.
        on_event_save_draft( ).
      WHEN `ACTIVATE`.
        on_event_activate( ).
      WHEN `DISCARD`.
        on_event_discard( ).
      WHEN `POPUP_CLOSE`.
        client->popup_destroy( ).
    ENDCASE.

  ENDMETHOD.


  METHOD on_event_generate.

    client->message_toast_display( z2ui5_cl_smpe_data_trd=>data_reset( ) ).
    data_read( ).
    client->view_model_update( ).

  ENDMETHOD.


  METHOD on_event_edit.

    DATA s_failed   TYPE RESPONSE FOR FAILED EARLY z2ui5_r_smpe_trd.
    DATA s_reported TYPE RESPONSE FOR REPORTED EARLY z2ui5_r_smpe_trd.

    DATA(uuid) = client->get_event_arg( 1 ).

    IF t_travels[ travel_uuid = uuid ]-has_draft = abap_false.

      " no draft yet: the draft action Edit copies the active instance
      " into a new draft instance
      MODIFY ENTITIES OF z2ui5_r_smpe_trd
        ENTITY travel
          EXECUTE Edit FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                                       %is_draft  = if_abap_behv=>mk-off ) ) )
        FAILED s_failed
        REPORTED s_reported.

    ELSE.

      " a draft already exists: the draft action Resume reactivates it,
      " so the user continues exactly where the last session ended
      MODIFY ENTITIES OF z2ui5_r_smpe_trd
        ENTITY travel
          EXECUTE Resume FROM VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                                         %is_draft  = if_abap_behv=>mk-on ) ) )
        FAILED s_failed
        REPORTED s_reported.

    ENDIF.

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      draft_read( uuid ).
      data_read( ).
      client->view_model_update( ).
      popup_edit_display( ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_save_draft.

    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        UPDATE FIELDS ( agencyid customerid begindate enddate bookingfee currencycode description )
        WITH VALUE #( ( %tky         = VALUE #( traveluuid = s_draft-travel_uuid
                                                %is_draft  = if_abap_behv=>mk-on )
                        agencyid     = s_draft-agency_id
                        customerid   = s_draft-customer_id
                        begindate    = s_draft-begin_date
                        enddate      = s_draft-end_date
                        bookingfee   = s_draft-booking_fee
                        currencycode = s_draft-currency
                        description  = s_draft-description ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( `Draft saved - the changes are kept even after logoff` ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_activate.

    " the validations of the business object run during activation -
    " an invalid draft stays a draft and the messages are displayed
    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        EXECUTE Activate FROM VALUE #( ( %tky = VALUE #( traveluuid = s_draft-travel_uuid
                                                         %is_draft  = if_abap_behv=>mk-on ) ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      client->popup_destroy( ).
      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( |Travel { s_draft-travel_id } activated| ).

    ENDIF.

  ENDMETHOD.


  METHOD on_event_discard.

    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        EXECUTE Discard FROM VALUE #( ( %tky = VALUE #( traveluuid = s_draft-travel_uuid
                                                        %is_draft  = if_abap_behv=>mk-on ) ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported-travel ).
      RETURN.

    ENDIF.

    IF data_save( ) = abap_true.

      client->popup_destroy( ).
      data_read( ).
      client->view_model_update( ).
      client->message_toast_display( |Draft of travel { s_draft-travel_id } discarded| ).

    ENDIF.

  ENDMETHOD.


  METHOD draft_read.

    READ ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        ALL FIELDS WITH VALUE #( ( %tky = VALUE #( traveluuid = uuid
                                                   %is_draft  = if_abap_behv=>mk-on ) ) )
      RESULT DATA(t_result).

    DATA(s_result) = t_result[ 1 ].
    s_draft = VALUE #(
      travel_uuid = uuid
      travel_id   = |{ s_result-travelid ALPHA = OUT }|
      agency_id   = |{ s_result-agencyid ALPHA = OUT }|
      customer_id = |{ s_result-customerid ALPHA = OUT }|
      begin_date  = |{ s_result-begindate }|
      end_date    = |{ s_result-enddate }|
      booking_fee = |{ s_result-bookingfee }|
      currency    = |{ s_result-currencycode }|
      description = |{ s_result-description }| ).

  ENDMETHOD.


  METHOD data_read.

    SELECT FROM z2ui5_r_smpe_trd
      FIELDS traveluuid,
             travelid,
             customerid,
             begindate,
             enddate,
             totalprice,
             currencycode,
             overallstatus,
             description
      ORDER BY travelid DESCENDING
      INTO TABLE @DATA(t_result)
      UP TO 20 ROWS.

    " a draft instance shares the key of its active instance - reading
    " the keys with %is_draft = on reveals which travels have a draft
    READ ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        FIELDS ( travelid ) WITH VALUE #( FOR s_row IN t_result
                                          ( %tky = VALUE #( traveluuid = s_row-traveluuid
                                                            %is_draft  = if_abap_behv=>mk-on ) ) )
      RESULT DATA(t_drafts)
      FAILED DATA(s_failed).

    t_travels = VALUE #( FOR s_result IN t_result
        ( travel_uuid    = |{ s_result-traveluuid }|
          travel_id      = |{ s_result-travelid ALPHA = OUT }|
          customer_id    = |{ s_result-customerid ALPHA = OUT }|
          begin_date     = |{ s_result-begindate DATE = ISO }|
          end_date       = |{ s_result-enddate DATE = ISO }|
          total_price    = |{ s_result-totalprice } { s_result-currencycode }|
          overall_status = z2ui5_cl_smpe_context=>status_get_text( s_result-overallstatus )
          status_state   = z2ui5_cl_smpe_context=>status_get_state( s_result-overallstatus )
          has_draft      = xsdbool( line_exists( t_drafts[ traveluuid = s_result-traveluuid ] ) )
          draft_text     = COND #( WHEN line_exists( t_drafts[ traveluuid = s_result-traveluuid ] )
                                   THEN `Draft` ) ) ).

  ENDMETHOD.


  METHOD data_save.

    COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trd
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed IS INITIAL.
      result = abap_true.

    ELSE.
      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported-travel ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    DATA(page) = view->shell(
        )->page(
            title          = `abap2UI5 - EML - 10 Travels with Draft Handling`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( ) ).

    DATA(table) = page->table( client->_bind( t_travels ) ).
    table->header_toolbar(
        )->toolbar(
            )->title( `Travels (Z2UI5_R_SMPE_TRD)`
            )->toolbar_spacer(
            )->button(
                text  = `Generate Demo Data`
                icon  = `sap-icon://add`
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
        )->column( )->text( `Draft` )->get_parent(
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
            )->object_status(
                text  = `{DRAFT_TEXT}`
                state = `Warning`
            )->button(
                icon    = `sap-icon://edit`
                tooltip = `Edit Travel`
                press   = client->_event( val = `EDIT` t_arg = VALUE #( ( `${TRAVEL_UUID}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD popup_edit_display.

    DATA(popup) = z2ui5_cl_xml_view=>factory_popup( ).
    DATA(dialog) = popup->dialog(
        title        = |Edit Travel { s_draft-travel_id } (Draft)|
        contentwidth = `30rem` ).

    dialog->simple_form( editable = abap_true
        )->content( `form`
        )->label( `Agency ID`
        )->input( client->_bind( s_draft-agency_id )
        )->label( `Customer ID`
        )->input( client->_bind( s_draft-customer_id )
        )->label( `Begin Date`
        )->date_picker(
            value       = client->_bind( s_draft-begin_date )
            valueformat = `yyyyMMdd`
        )->label( `End Date`
        )->date_picker(
            value       = client->_bind( s_draft-end_date )
            valueformat = `yyyyMMdd`
        )->label( `Booking Fee`
        )->input( client->_bind( s_draft-booking_fee )
        )->label( `Currency`
        )->input( client->_bind( s_draft-currency )
        )->label( `Description`
        )->input( client->_bind( s_draft-description ) ).

    dialog->buttons(
        )->button(
            text  = `Activate`
            press = client->_event( `ACTIVATE` )
            type  = `Emphasized`
        )->button(
            text  = `Save Draft`
            press = client->_event( `SAVE_DRAFT` )
        )->button(
            text  = `Discard Draft`
            press = client->_event( `DISCARD` )
            type  = `Reject`
        )->button(
            text  = `Close`
            press = client->_event( `POPUP_CLOSE` ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
