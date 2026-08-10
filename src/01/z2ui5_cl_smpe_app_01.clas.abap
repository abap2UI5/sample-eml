"! <p class="shorttext synchronized">abap2UI5 - EML sample 01 - read travel</p>
"! Reads one instance by its key.
"!
"!     READ ENTITIES OF z2ui5_r_smpe_trv
"!       ENTITY travel
"!         ALL FIELDS WITH VALUE #( ( travelid = travel_id ) )
"!       RESULT DATA(t_result)
"!       FAILED DATA(s_failed).
"!
"! Worth knowing: a key that does not exist is not an exception. It comes back
"! in FAILED and RESULT stays empty, so the response is what you check - never
"! sy-subrc.
CLASS z2ui5_cl_smpe_app_01 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_travel,
        agency_id      TYPE string,
        customer_id    TYPE string,
        begin_date     TYPE string,
        end_date       TYPE string,
        total_price    TYPE string,
        overall_status TYPE string,
        description    TYPE string,
      END OF ty_s_travel.
    DATA s_travel TYPE ty_s_travel.

    DATA travel_id TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS data_read.
    METHODS view_display.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_app_01 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      view_display( ).
    ELSEIF client->check_on_event( `READ` ).
      data_read( ).
    ENDIF.

  ENDMETHOD.


  METHOD data_read.

    READ ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        ALL FIELDS WITH VALUE #( ( travelid = travel_id ) )
      RESULT DATA(t_result)
      FAILED DATA(s_failed).

    IF s_failed-travel IS NOT INITIAL.

      s_travel = VALUE #( ).
      client->message_box_display(
          text = |Travel { travel_id } does not exist|
          type = `error` ).

    ELSE.

      DATA(s_result) = t_result[ 1 ].
      s_travel = VALUE #(
        agency_id      = |{ s_result-agencyid ALPHA = OUT }|
        customer_id    = |{ s_result-customerid ALPHA = OUT }|
        begin_date     = |{ s_result-begindate DATE = ISO }|
        end_date       = |{ s_result-enddate DATE = ISO }|
        total_price    = |{ s_result-totalprice } { s_result-currencycode }|
        overall_status = z2ui5_cl_smpe_context=>status_get_text( s_result-overallstatus )
        description    = |{ s_result-description }| ).

    ENDIF.

    client->view_model_update( ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    view->shell(
        )->page(
            title          = `abap2UI5 - EML - 01 Read Travel`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( )
            )->simple_form(
                title    = `READ ENTITIES OF Z2UI5_R_SMPE_TRV`
                editable = abap_true
                )->content( `form`
                )->label( `Travel ID`
                )->input(
                    value       = client->_bind( travel_id )
                    placeholder = `Enter a travel id, e.g. 1`
                )->button(
                    text  = `Read`
                    press = client->_event( `READ` )
                    type  = `Emphasized`
                )->label( `Agency`
                )->input(
                    value   = client->_bind( s_travel-agency_id )
                    enabled = abap_false
                )->label( `Customer`
                )->input(
                    value   = client->_bind( s_travel-customer_id )
                    enabled = abap_false
                )->label( `Begin Date`
                )->input(
                    value   = client->_bind( s_travel-begin_date )
                    enabled = abap_false
                )->label( `End Date`
                )->input(
                    value   = client->_bind( s_travel-end_date )
                    enabled = abap_false
                )->label( `Total Price`
                )->input(
                    value   = client->_bind( s_travel-total_price )
                    enabled = abap_false
                )->label( `Status`
                )->input(
                    value   = client->_bind( s_travel-overall_status )
                    enabled = abap_false
                )->label( `Description`
                )->input(
                    value   = client->_bind( s_travel-description )
                    enabled = abap_false ).
    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
