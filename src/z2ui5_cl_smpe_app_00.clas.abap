"! <p class="shorttext synchronized">abap2UI5 EML sample 00 - overview</p>
"! The entry point of this repository: every sample in one list, one press
"! away. Start it with ?app_start=z2ui5_cl_smpe_app_00.
"!
"! The Open button of a row starts its sample in a NEW BROWSER TAB, so the
"! overview stays where it is and several samples can run side by side. That
"! is a pure frontend action: the row carries the finished ?app_start= URL of
"! its class and the button is wired with _event_client( ), which opens the
"! tab inside the click handler without a roundtrip - a window.open( ) from a
"! server response would be swallowed by the popup blocker.
CLASS z2ui5_cl_smpe_app_00 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_sample,
        no        TYPE string,
        title     TYPE string,
        statement TYPE string,
        classname TYPE string,
        "! the app URL of CLASSNAME - the frontend opens it in a new tab
        url       TYPE string,
      END OF ty_s_sample.
    TYPES ty_t_sample TYPE STANDARD TABLE OF ty_s_sample WITH EMPTY KEY.

    "! samples 01-10, split by the business object they run against
    DATA t_travel TYPE ty_t_sample.
    DATA t_draft  TYPE ty_t_sample.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    CONSTANTS:
      BEGIN OF cs_event,
        regenerate TYPE string VALUE `REGENERATE` ##NO_TEXT,
      END OF cs_event.

    METHODS on_event.
    METHODS view_display.
    METHODS model_init.

    "! one table per business object - same markup, different binding
    METHODS render_table
      IMPORTING
        page  TYPE REF TO z2ui5_cl_ai_xml
        title TYPE string
        items TYPE string.

    "! one row of the list
    METHODS sample
      IMPORTING
        no            TYPE string
        title         TYPE string
        statement     TYPE string
        app           TYPE REF TO z2ui5_if_app
      RETURNING
        VALUE(result) TYPE ty_s_sample.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_app_00 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ELSEIF client->check_on_navigated( ).
      " a sample the user left with the back button lands here - without
      " this branch the overview would come back blank
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    CASE client->get( )-event.

      WHEN cs_event-regenerate.

        " both business objects at once - the samples above run against the
        " one without draft, the samples below against the draft enabled one,
        " and an empty table is the most common reason a sample looks broken.
        " data_reset( ) deletes first, so the travel ids stay 1, 2, 3.
        client->message_toast_display( |{ z2ui5_cl_smpe_data_trv=>data_reset( ) } | &&
                                       |{ z2ui5_cl_smpe_data_trd=>data_reset( ) }| ).

    ENDCASE.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).

    DATA(page) = view->open( n = `View` ns = `mvc`
        )->a( n = `xmlns`        v = `sap.m`
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `displayBlock` v = `true`
        )->a( n = `height`       v = `100%`
        )->open( `Shell`
        )->open( `Page`
            )->a( n = `title` v = `abap2UI5 - EML - 00 Overview`
            )->a( n = `class` v = `sapUiContentPadding` ).

    " the button sits in the page header, so it stays reachable no matter
    " which of the two lists the user has scrolled to
    page->open( `headerContent`
        )->leaf( `Button`
            )->a( n = `text`  v = `Regenerate Demo Data`
            )->a( n = `icon`  v = `sap-icon://refresh`
            )->a( n = `press` v = client->_event( cs_event-regenerate ) ).

    page->leaf( `MessageStrip`
        )->a( n = `text`     v = `Every EML sample of this repository, in the order of the README. ` &&
                                 `Press Open to start one in a new tab. Empty lists? Press ` &&
                                 `Regenerate Demo Data above - it fills both business objects ` &&
                                 `with the same set Z2UI5_CL_SMPE_DATA_TRV / _TRD create with F9.`
        )->a( n = `showIcon` v = `true`
        )->a( n = `class`    v = `sapUiSmallMarginBottom` ).

    render_table( page  = page
                  title = `Z2UI5_R_SMPE_TRV - business object without draft`
                  items = client->_bind( t_travel ) ).

    render_table( page  = page
                  title = `Z2UI5_R_SMPE_TRD - draft enabled business object`
                  items = client->_bind( t_draft ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD render_table.

    DATA(table) = page->open( `Table`
        )->a( n = `items` v = items
        )->a( n = `class` v = `sapUiSmallMarginBottom` ).

    table->open( `headerToolbar`
        )->open( `Toolbar`
            )->leaf( `Title`
                )->a( n = `text` v = title ).

    table->open( `columns`
        )->open( `Column`
            )->a( n = `width` v = `3rem`
            )->leaf( `Text`
                )->a( n = `text` v = `#`
        )->shut(
        )->open( `Column`
            )->leaf( `Text`
                )->a( n = `text` v = `Sample`
        )->shut(
        )->open( `Column`
            )->leaf( `Text`
                )->a( n = `text` v = `EML`
        )->shut(
        )->open( `Column`
            )->leaf( `Text`
                )->a( n = `text` v = `Class`
        )->shut(
        )->open( `Column`
            )->a( n = `width`  v = `8rem`
            )->a( n = `hAlign` v = `End`
            )->leaf( `Text`
                )->a( n = `text` v = `Demo` ).

    table->open( `items`
        )->open( `ColumnListItem`
            )->open( `cells`
                )->leaf( `Text`
                    )->a( n = `text` v = `{NO}`
                )->leaf( `Text`
                    )->a( n = `text` v = `{TITLE}`
                )->leaf( `Text`
                    )->a( n = `text` v = `{STATEMENT}`
                )->leaf( `Text`
                    )->a( n = `text` v = `{CLASSNAME}`
                )->leaf( `Button`
                    )->a( n = `text` v = `Open`
                    )->a( n = `icon` v = `sap-icon://play`
                    " ${URL} is resolved by UI5 against the row the button
                    " sits in, so one wire serves every sample - and
                    " _event_client keeps it a frontend action, which is what
                    " lets the browser accept the new tab
                    )->a( n = `press` v = client->_event_client(
                                              val   = client->cs_event-open_new_tab
                                              t_arg = VALUE #( ( `${URL}` ) ) ) ).

  ENDMETHOD.


  METHOD sample.

    " read off the instance instead of typed as a literal: the compiler checks
    " the NEW below, so renaming a sample class breaks the build instead of
    " this list
    DATA(classname) = z2ui5_cl_util=>rtti_get_classname_by_ref( app ).

    " the address the browser has to open for that class - same ICF node and
    " same url parameters as the running overview, only app_start exchanged
    DATA(s_config) = client->get( )-s_config.

    result = VALUE #( no        = no
                      title     = title
                      statement = statement
                      classname = classname
                      url       = z2ui5_cl_util=>app_get_url( classname = classname
                                                              origin    = s_config-origin
                                                              pathname  = s_config-pathname
                                                              search    = s_config-search
                                                              hash      = s_config-hash ) ).

  ENDMETHOD.


  METHOD model_init.

    t_travel = VALUE #(
      ( sample( no        = `01`
                title     = `Read a travel`
                statement = `READ ENTITIES`
                app       = NEW z2ui5_cl_smpe_app_01( ) ) )
      ( sample( no        = `02`
                title     = `Create a travel`
                statement = `MODIFY ... CREATE, key from MAPPED`
                app       = NEW z2ui5_cl_smpe_app_02( ) ) )
      ( sample( no        = `03`
                title     = `Update a travel`
                statement = `MODIFY ... UPDATE FIELDS`
                app       = NEW z2ui5_cl_smpe_app_03( ) ) )
      ( sample( no        = `04`
                title     = `Delete a travel`
                statement = `MODIFY ... DELETE FROM`
                app       = NEW z2ui5_cl_smpe_app_04( ) ) )
      ( sample( no        = `05`
                title     = `Manage travels - the whole app`
                statement = `MODIFY ... EXECUTE, COMMIT ENTITIES RESPONSE OF`
                app       = NEW z2ui5_cl_smpe_app_05( ) ) ) ).

    t_draft = VALUE #(
      ( sample( no        = `06`
                title     = `Which travels have a draft?`
                statement = `READ ... %is_draft = mk-on`
                app       = NEW z2ui5_cl_smpe_app_06( ) ) )
      ( sample( no        = `07`
                title     = `Enter draft mode`
                statement = `EXECUTE Edit / Resume`
                app       = NEW z2ui5_cl_smpe_app_07( ) ) )
      ( sample( no        = `08`
                title     = `Change and save a draft`
                statement = `UPDATE ... %is_draft = mk-on`
                app       = NEW z2ui5_cl_smpe_app_08( ) ) )
      ( sample( no        = `09`
                title     = `Leave draft mode`
                statement = `EXECUTE Activate / Discard`
                app       = NEW z2ui5_cl_smpe_app_09( ) ) )
      ( sample( no        = `10`
                title     = `Travels with draft handling - the whole app`
                statement = `everything above`
                app       = NEW z2ui5_cl_smpe_app_10( ) ) ) ).

  ENDMETHOD.

ENDCLASS.
