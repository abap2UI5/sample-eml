CLASS z2ui5_cl_smpe_app_02 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_travel,
        agency_id   TYPE string,
        customer_id TYPE string,
        begin_date  TYPE string,
        end_date    TYPE string,
        booking_fee TYPE string,
        currency    TYPE string,
        description TYPE string,
      END OF ty_s_travel.
    DATA s_travel TYPE ty_s_travel.

    DATA created_id TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS data_create.
    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_app_02 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      " prefilled with a set that passes both validations of the business
      " object - CustomerId is filled and EndDate is not before BeginDate -
      " so pressing Create right away produces a travel. Change a value and
      " the same button shows what the validations answer instead.
      " CONV d( ) is what turns the sum back into a date: sy-datum + 14 is
      " calculated as a day number, and a string template renders that number
      " instead of a date - the field showed 739853
      DATA(end_date) = CONV d( sy-datum + 14 ).

      s_travel = VALUE #( agency_id   = `070001`
                          customer_id = `000001`
                          begin_date  = |{ sy-datum }|
                          end_date    = |{ end_date }|
                          booking_fee = `20.00`
                          currency    = `EUR`
                          description = `New travel created from sample 02` ).
      view_display( ).
    ELSEIF client->check_on_event( `CREATE` ).
      data_create( ).
    ENDIF.

  ENDMETHOD.


  METHOD data_create.

    " CREATE hands the new instance to the transactional buffer. The %cid is
    " a temporary id chosen by the caller: the business object does not know
    " the key yet, so MAPPED reports it back under that %cid.
    MODIFY ENTITIES OF z2ui5_r_smpe_trv
      ENTITY travel
        CREATE FIELDS ( agencyid customerid begindate enddate bookingfee currencycode description )
        WITH VALUE #( ( %cid         = `CREATE_1`
                        agencyid     = s_travel-agency_id
                        customerid   = s_travel-customer_id
                        begindate    = s_travel-begin_date
                        enddate      = s_travel-end_date
                        bookingfee   = s_travel-booking_fee
                        currencycode = s_travel-currency
                        description  = s_travel-description ) )
      MAPPED DATA(s_mapped)
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported-travel ).
      RETURN.

    ENDIF.

    " nothing is persisted before the COMMIT - and the validations of the
    " business object only run now, so this is where they can still fail
    COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trv
      FAILED DATA(s_failed_commit)
      REPORTED DATA(s_reported_commit).

    IF s_failed_commit IS NOT INITIAL.

      z2ui5_cl_smpe_context=>msg_display( client = client val = s_reported_commit-travel ).
      RETURN.

    ENDIF.

    " thanks to early numbering the key assigned by the business object is
    " available in MAPPED, addressed by the %cid sent above
    created_id = |{ s_mapped-travel[ %cid = `CREATE_1` ]-travelid ALPHA = OUT }|.
    client->message_toast_display( |Travel { created_id } created| ).
    client->view_model_update( ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_xml_view=>factory( ).
    view->shell(
        )->page(
            title          = `abap2UI5 - EML - 02 Create Travel`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( )
            )->simple_form(
                title    = `MODIFY ENTITIES OF Z2UI5_R_SMPE_TRV ... CREATE`
                editable = abap_true
                )->content( `form`
                )->label( `Agency ID`
                )->input(
                    value       = client->_bind( s_travel-agency_id )
                    placeholder = `e.g. 070001`
                )->label( `Customer ID`
                )->input(
                    value       = client->_bind( s_travel-customer_id )
                    placeholder = `e.g. 000001`
                )->label( `Begin Date`
                )->date_picker(
                    value       = client->_bind( s_travel-begin_date )
                    valueformat = `yyyyMMdd`
                )->label( `End Date`
                )->date_picker(
                    value       = client->_bind( s_travel-end_date )
                    valueformat = `yyyyMMdd`
                )->label( `Booking Fee`
                )->input(
                    value       = client->_bind( s_travel-booking_fee )
                    placeholder = `e.g. 20.00`
                )->label( `Currency`
                )->input( client->_bind( s_travel-currency )
                )->label( `Description`
                )->input( client->_bind( s_travel-description )
                )->label( ``
                )->button(
                    text  = `Create`
                    press = client->_event( `CREATE` )
                    type  = `Emphasized`
                )->label( `Created Travel ID`
                )->input(
                    value   = client->_bind( created_id )
                    enabled = abap_false ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
