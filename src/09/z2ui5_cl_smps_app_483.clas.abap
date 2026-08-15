CLASS z2ui5_cl_smps_app_483 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA:
      BEGIN OF nav_params,
        product  TYPE string,
        quantity TYPE string,
      END OF nav_params.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smps_app_483 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    IF client->check_on_init( ).

      nav_params-product  = `102343333`.
      nav_params-quantity = `500`.

      IF client->get( )-check_launchpad_active = abap_false.
        client->message_box_display( `No Launchpad Active, Sample not working!` ).
      ENDIF.

      DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
          )->ele( n = `View` ns = `mvc`
              )->a( n = `displayBlock` v = `true`
              )->a( n = `height`       v = `100%`
              )->a( n = `xmlns`        v = `sap.m`
              )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
              )->a( n = `xmlns:core`   v = `sap.ui.core`
              )->a( n = `xmlns:form`   v = `sap.ui.layout.form` ).
      DATA(page) = view->ele( `Shell`
          )->ele( `Page`
              )->a( n = `title`          v = `abap2UI5 - Launchpad - Cross-App Navigation (Sender)`
              )->a( n = `showNavButton`  b = client->check_app_prev_stack( )
              )->a( n = `navButtonPress` v = client->_event_nav_app_leave( )
              )->a( n = `showHeader`     b = xsdbool( abap_false = client->get( )-check_launchpad_active ) ).

      page->tag( `MessageStrip`
          )->a( n = `text`     v = `SENDER side of launchpad cross-app navigation: the button navigates to ` &&
                     `the receiver tile via follow_up_action( cs_event-cross_app_nav_to_ext ), ` &&
                     `handing over the bound Product and Quantity values as navigation ` &&
                     `parameters - the receiver (z2ui5_cl_smps_app_484) reads them from its ` &&
                     `startup parameters. ` &&
                     `Only works inside a launchpad with both tiles configured.`
          )->a( n = `type`     v = `Information`
          )->a( n = `showIcon` b = abap_true
          )->a( n = `class`    v = `sapUiSmallMargin` ).

      page->ele( n = `SimpleForm` ns = `form`
          )->a( n = `title`    v = `Cross-App Navigation - Sender`
          )->a( n = `editable` b = abap_true
          )->ele( n = `content` ns = `form`
              )->tag( `Label`
                  )->a( n = `text` v = `Product (sent as navigation parameter)`
              )->tag( `Input`
                  )->a( n = `value` v = client->_bind( nav_params-product )
              )->tag( `Label`
                  )->a( n = `text` v = `Quantity (sent as navigation parameter)`
              )->tag( `Input`
                  )->a( n = `value` v = client->_bind( nav_params-quantity )
              )->tag( `Button`
                  )->a( n = `press`   v = client->follow_up_action( client->cs_event-cross_app_nav_to_prev_app )
                  )->a( n = `text`    v = `back to the previous app`
                  )->a( n = `visible` v = client->get( )-check_launchpad_active
              )->tag( `Button`
                  )->a( n = `press`   v = client->follow_up_action(
                      val   = client->cs_event-cross_app_nav_to_ext
                      t_arg = VALUE #(
                          ( `{ semanticObject: "Z2UI5_CL_LP_SAMPLE_04",  action: "display" }` )
                          ( `$` && client->_bind( nav_params ) ) ) )
                  )->a( n = `text`    v = `navigate to the receiver app`
                  )->a( n = `visible` v = client->get( )-check_launchpad_active ).

      client->view_display( view->stringify( ) ).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
