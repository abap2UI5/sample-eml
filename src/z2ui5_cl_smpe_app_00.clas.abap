"! <p class="shorttext synchronized">abap2UI5 samples-ext 00 - overview</p>
"! The entry point of this repository: every sample of every package in one
"! list, one press away. Start it with ?app_start=z2ui5_cl_smpe_app_00.
"!
"! The Open button of a row starts its sample in a NEW BROWSER TAB, so the
"! overview stays where it is and several samples can run side by side. That
"! is a pure frontend action: the row carries the finished ?app_start= URL of
"! its class and the button is wired with _event_client( ), which opens the
"! tab inside the click handler without a roundtrip - a window.open( ) from a
"! server response would be swallowed by the popup blocker.
"!
"! Every sample is referenced BY NAME and looked up at runtime, never with a
"! NEW z2ui5_cl_smpe_app_<no>( ). A static reference would compile the whole
"! repository into this one class, and this class has to survive the two
"! cases where that is exactly what must not happen:
"!
"!   - a package the system cannot activate. src/05 needs RAP business
"!     events, src/07 needs on-premise APC - on a release or a stack without
"!     them the classes stay inactive, and a static reference would take the
"!     overview down with them instead of listing them as unavailable.
"!   - a package that is not installed at all, because the system only got
"!     part of this repository.
"!
"! So the list is complete no matter what is on the system: what is there
"! opens, what is missing says so in its Status column and keeps its Open
"! button disabled. The price is that a renamed class no longer breaks the
"! build - the CI check `npm run check:overview` covers that instead.
CLASS z2ui5_cl_smpe_app_00 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_sample,
        no        TYPE string,
        title     TYPE string,
        detail    TYPE string,
        classname TYPE string,
        "! the app URL of CLASSNAME - the frontend opens it in a new tab
        url       TYPE string,
        "! the class answered to CREATE OBJECT, so the sample can be started
        installed TYPE abap_bool,
        "! empty while INSTALLED - only the missing rows explain themselves
        status    TYPE string,
        state     TYPE string,
      END OF ty_s_sample.
    TYPES ty_t_sample TYPE STANDARD TABLE OF ty_s_sample WITH EMPTY KEY.

    "! one table per package - the order is the reading order of the README
    DATA t_odata     TYPE ty_t_sample.
    DATA t_smart     TYPE ty_t_sample.
    DATA t_rap       TYPE ty_t_sample.
    DATA t_draft     TYPE ty_t_sample.
    DATA t_events    TYPE ty_t_sample.
    DATA t_stateful  TYPE ty_t_sample.
    DATA t_websocket TYPE ty_t_sample.
    DATA t_mime      TYPE ty_t_sample.
    DATA t_launchpad TYPE ty_t_sample.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    "! at least one of the two demo data classes is on the system, so the
    "! Regenerate Demo Data button has something to call
    DATA demo_data_installed TYPE abap_bool.

    CONSTANTS:
      BEGIN OF cs_event,
        regenerate TYPE string VALUE `REGENERATE` ##NO_TEXT,
      END OF cs_event.

    CONSTANTS:
      "! the demo data of the two RAP packages - called by name for the same
      "! reason the samples are, see the class documentation
      BEGIN OF cs_class,
        data_trv TYPE string VALUE `Z2UI5_CL_SMPE_DATA_TRV` ##NO_TEXT,
        data_trd TYPE string VALUE `Z2UI5_CL_SMPE_DATA_TRD` ##NO_TEXT,
      END OF cs_class.

    METHODS on_event.
    METHODS view_display.
    METHODS model_init.

    "! one package each - same markup, different binding
    METHODS render_package
      IMPORTING
        page  TYPE REF TO z2ui5_cl_ai_xml
        title TYPE string
        hint  TYPE string
        items TYPE string.

    "! one row of a list, including the runtime lookup of CLASSNAME
    METHODS sample
      IMPORTING
        no            TYPE string
        title         TYPE string
        detail        TYPE string
        classname     TYPE string
      RETURNING
        VALUE(result) TYPE ty_s_sample.

    "! is the class on this system and instantiable? The framework asks the
    "! same question the same way when you type a class name into its start
    "! page - an inactive or absent class raises, it does not return a flag.
    METHODS class_check_installed
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    "! calls DATA_RESET on one of the demo data classes, empty if absent
    METHODS data_reset
      IMPORTING
        classname     TYPE string
      RETURNING
        VALUE(result) TYPE string.

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

        " both business objects at once - the samples of src/03 run against
        " the one without draft, those of src/04 against the draft enabled
        " one, and an empty table is the most common reason a sample looks
        " broken. data_reset( ) deletes first, so the travel ids stay 1, 2, 3.
        DATA(text) = condense( |{ data_reset( cs_class-data_trv ) } { data_reset( cs_class-data_trd ) }| ).
        IF text IS INITIAL.
          text = `No demo data on this system - the two RAP packages are not installed`.
        ENDIF.
        client->message_toast_display( text ).

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
            )->a( n = `title` v = `abap2UI5 - samples-ext - 00 Overview`
            )->a( n = `class` v = `sapUiContentPadding` ).

    " the button sits in the page header, so it stays reachable no matter
    " which package the user has scrolled to. It is hidden outright when
    " neither RAP package is installed - there would be nothing to fill.
    page->open( `headerContent`
        )->leaf( `Button`
            )->a( n = `text`    v = `Regenerate Demo Data`
            )->a( n = `icon`    v = `sap-icon://refresh`
            )->a( n = `visible` v = z2ui5_cl_ai_xml=>as_bool( demo_data_installed )
            )->a( n = `press`   v = client->_event( cs_event-regenerate ) ).

    page->leaf( `MessageStrip`
        )->a( n = `text`     v = `Every sample of this repository, one package per section - Open starts it ` &&
                                 `in a new browser tab. A row whose Status says so is not on this system: ` &&
                                 `either the package was not installed, or the release cannot activate it. ` &&
                                 `Everything else runs. The RAP sections need data - press Regenerate Demo ` &&
                                 `Data above if their samples look empty.`
        )->a( n = `showIcon` v = `true`
        )->a( n = `class`    v = `sapUiSmallMarginBottom` ).

    render_package( page  = page
                    title = `01 - OData`
                    hint  = `bind a table to an OData V2 model - needs an activated OData V2 service`
                    items = client->_bind( t_odata ) ).

    render_package( page  = page
                    title = `02 - Smart Controls`
                    hint  = `sap.ui.comp driven by OData metadata - needs SAPUI5 and an activated Gateway service`
                    items = client->_bind( t_smart ) ).

    render_package( page  = page
                    title = `03 - RAP`
                    hint  = `one EML statement per sample on Z2UI5_R_SMPE_TRV - the business object ships with the package`
                    items = client->_bind( t_rap ) ).

    render_package( page  = page
                    title = `04 - RAP with Draft`
                    hint  = `Z2UI5_R_SMPE_TRD - start at 06, it carries the trick the other three reuse`
                    items = client->_bind( t_draft ) ).

    render_package( page  = page
                    title = `05 - Business Events`
                    hint  = `needs a release that already carries RAP business events - open both samples side by side`
                    items = client->_bind( t_events ) ).

    render_package( page  = page
                    title = `06 - Stateful Sessions / Locks`
                    hint  = `ABAP Standard (on-premise) - keep SM12 open next to the browser and start with 486`
                    items = client->_bind( t_stateful ) ).

    render_package( page  = page
                    title = `07 - AMC/APC`
                    hint  = `on-premise WebSockets - activate the ICF node /sap/bc/apc/sap/z2ui5_apc_smp_2`
                    items = client->_bind( t_websocket ) ).

    render_package( page  = page
                    title = `08 - MIME Play Audio`
                    hint  = `activate the ICF service /SAP/PUBLIC/BC/ABAP/mime_demo`
                    items = client->_bind( t_mime ) ).

    render_package( page  = page
                    title = `09 - Launchpad`
                    hint  = `these four show what the shell adds - start them from a launchpad tile, not from here`
                    items = client->_bind( t_launchpad ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD render_package.

    " collapsible: nine packages are a long page, and most readers came for
    " one of them
    DATA(panel) = page->open( `Panel`
        )->a( n = `headerText` v = title
        )->a( n = `expandable` v = `true`
        )->a( n = `expanded`   v = `true`
        )->a( n = `width`      v = `auto`
        )->a( n = `class`      v = `sapUiSmallMarginBottom` ).

    panel->leaf( `Text`
        )->a( n = `text`  v = hint
        )->a( n = `class` v = `sapUiSmallMarginBottom` ).

    DATA(table) = panel->open( `Table`
        )->a( n = `items` v = items ).

    table->open( `columns`
        )->open( `Column`
            )->a( n = `width` v = `4rem`
            )->leaf( `Text`
                )->a( n = `text` v = `#`
        )->shut(
        )->open( `Column`
            )->leaf( `Text`
                )->a( n = `text` v = `Sample`
        )->shut(
        )->open( `Column`
            )->a( n = `demandPopin`    v = `true`
            )->a( n = `minScreenWidth` v = `Tablet`
            )->leaf( `Text`
                )->a( n = `text` v = `Shows`
        )->shut(
        )->open( `Column`
            )->a( n = `demandPopin`    v = `true`
            )->a( n = `minScreenWidth` v = `Desktop`
            )->leaf( `Text`
                )->a( n = `text` v = `Class`
        )->shut(
        )->open( `Column`
            )->a( n = `width` v = `9rem`
            )->leaf( `Text`
                )->a( n = `text` v = `Status`
        )->shut(
        )->open( `Column`
            )->a( n = `width`  v = `7rem`
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
                    )->a( n = `text` v = `{DETAIL}`
                )->leaf( `Text`
                    )->a( n = `text` v = `{CLASSNAME}`
                )->leaf( `ObjectStatus`
                    )->a( n = `text`  v = `{STATUS}`
                    )->a( n = `state` v = `{STATE}`
                )->leaf( `Button`
                    )->a( n = `text` v = `Open`
                    )->a( n = `icon` v = `sap-icon://play`
                    " a sample that is not on this system has no URL worth
                    " opening - the row stays, the button does not work
                    )->a( n = `enabled` v = `{INSTALLED}`
                    " ${URL} is resolved by UI5 against the row the button
                    " sits in, so one wire serves every sample - and
                    " _event_client keeps it a frontend action, which is what
                    " lets the browser accept the new tab
                    )->a( n = `press` v = client->_event_client(
                                              val   = client->cs_event-open_new_tab
                                              t_arg = VALUE #( ( `${URL}` ) ) ) ).

  ENDMETHOD.


  METHOD sample.

    " the address the browser has to open for that class - same ICF node and
    " same url parameters as the running overview, only app_start exchanged
    DATA(s_config) = client->get( )-s_config.

    result = VALUE #( no        = no
                      title     = title
                      detail    = detail
                      classname = to_upper( classname )
                      installed = class_check_installed( classname )
                      url       = z2ui5_cl_util=>app_get_url( classname = classname
                                                              origin    = s_config-origin
                                                              pathname  = s_config-pathname
                                                              search    = s_config-search
                                                              hash      = s_config-hash ) ).

    " an enum typed property rejects the empty string, so the rows that are
    " fine say None rather than nothing
    result-state  = COND #( WHEN result-installed = abap_true THEN `None` ELSE `Warning` ).
    result-status = COND #( WHEN result-installed = abap_true THEN `` ELSE `not on this system` ).

  ENDMETHOD.


  METHOD class_check_installed.

    DATA obj TYPE REF TO object ##NEEDED.

    TRY.
        CREATE OBJECT obj TYPE (val).
        result = abap_true.
      CATCH cx_root ##CATCH_ALL.
        " absent, inactive, or not activatable on this release - for the
        " overview these are the same answer: it cannot be started
        result = abap_false.
    ENDTRY.

  ENDMETHOD.


  METHOD data_reset.

    TRY.
        CALL METHOD (classname)=>('DATA_RESET')
          RECEIVING
            result = result.
      CATCH cx_root ##CATCH_ALL.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.


  METHOD model_init.

    demo_data_installed = boolc( class_check_installed( cs_class-data_trv ) = abap_true
                              OR class_check_installed( cs_class-data_trd ) = abap_true ).

    t_odata = VALUE #(
      ( sample( no        = `315`
                title     = `Two OData models in one view`
                detail    = `one table bound to each, column headers from the metadata`
                classname = `Z2UI5_CL_SMPE_APP_315` ) ) ).

    t_smart = VALUE #(
      ( sample( no        = `313`
                title     = `SmartFilterBar and SmartTable`
                detail    = `with variant management - UI_PRODUCTLIST`
                classname = `Z2UI5_CL_SMPE_APP_313` ) )
      ( sample( no        = `314`
                title     = `Switch the default model`
                detail    = `device, HTTP and OData model side by side - GWSAMPLE_BASIC`
                classname = `Z2UI5_CL_SMPE_APP_314` ) )
      ( sample( no        = `319`
                title     = `SmartMultiInput to SELECT-OPTIONS`
                detail    = `UI conditions mapped 1:1 onto an ABAP range table`
                classname = `Z2UI5_CL_SMPE_APP_319` ) )
      ( sample( no        = `475`
                title     = `SmartField inside a SmartForm`
                detail    = `GWSAMPLE_BASIC`
                classname = `Z2UI5_CL_SMPE_APP_475` ) )
      ( sample( no        = `476`
                title     = `SmartForm, display/edit toggle`
                detail    = `GWSAMPLE_BASIC`
                classname = `Z2UI5_CL_SMPE_APP_476` ) )
      ( sample( no        = `477`
                title     = `SmartFilterBar driving a SmartTable`
                detail    = `GWSAMPLE_BASIC`
                classname = `Z2UI5_CL_SMPE_APP_477` ) )
      ( sample( no        = `478`
                title     = `Page variant management`
                detail    = `GWSAMPLE_BASIC`
                classname = `Z2UI5_CL_SMPE_APP_478` ) )
      ( sample( no        = `479`
                title     = `SmartChart with NavigationPopover`
                detail    = `an analytical service - you supply the path`
                classname = `Z2UI5_CL_SMPE_APP_479` ) ) ).

    t_rap = VALUE #(
      ( sample( no        = `01`
                title     = `Read a travel`
                detail    = `READ ENTITIES`
                classname = `Z2UI5_CL_SMPE_APP_01` ) )
      ( sample( no        = `02`
                title     = `Create a travel`
                detail    = `MODIFY ... CREATE, key from MAPPED`
                classname = `Z2UI5_CL_SMPE_APP_02` ) )
      ( sample( no        = `03`
                title     = `Update a travel`
                detail    = `MODIFY ... UPDATE FIELDS`
                classname = `Z2UI5_CL_SMPE_APP_03` ) )
      ( sample( no        = `04`
                title     = `Delete a travel`
                detail    = `MODIFY ... DELETE FROM`
                classname = `Z2UI5_CL_SMPE_APP_04` ) )
      ( sample( no        = `05`
                title     = `Manage travels - the complete app`
                detail    = `01-04 plus EXECUTE and COMMIT ENTITIES RESPONSE OF`
                classname = `Z2UI5_CL_SMPE_APP_05` ) ) ).

    t_draft = VALUE #(
      ( sample( no        = `06`
                title     = `Which travels have a draft?`
                detail    = `READ ... %is_draft = mk-on`
                classname = `Z2UI5_CL_SMPE_APP_06` ) )
      ( sample( no        = `07`
                title     = `Enter draft mode`
                detail    = `EXECUTE Edit / Resume`
                classname = `Z2UI5_CL_SMPE_APP_07` ) )
      ( sample( no        = `08`
                title     = `Change and save a draft`
                detail    = `UPDATE ... %is_draft = mk-on`
                classname = `Z2UI5_CL_SMPE_APP_08` ) )
      ( sample( no        = `09`
                title     = `Leave draft mode`
                detail    = `EXECUTE Activate / Discard`
                classname = `Z2UI5_CL_SMPE_APP_09` ) )
      ( sample( no        = `10`
                title     = `Manage travels with draft - the complete app`
                detail    = `06-09 in one screen`
                classname = `Z2UI5_CL_SMPE_APP_10` ) ) ).

    t_events = VALUE #(
      ( sample( no        = `11`
                title     = `Create tickets through the BO`
                detail    = `every create and update raises an entity event`
                classname = `Z2UI5_CL_SMPE_APP_11` ) )
      ( sample( no        = `12`
                title     = `The event log`
                detail    = `what the handler wrote, newest first`
                classname = `Z2UI5_CL_SMPE_APP_12` ) ) ).

    t_stateful = VALUE #(
      ( sample( no        = `486`
                title     = `The basics - a counter in a static container`
                detail    = `counts up while the session is stateful, starts over once it is not`
                classname = `Z2UI5_CL_SMPE_APP_486` ) )
      ( sample( no        = `485`
                title     = `Set and read an ENQUEUE lock`
                detail    = `ENQUEUE_E_TABLE and ENQUEUE_READ, end and restart the session`
                classname = `Z2UI5_CL_SMPE_APP_485` ) )
      ( sample( no        = `490`
                title     = `One lock per screen`
                detail    = `every Next Lock View takes the next VARKEY, going back releases it`
                classname = `Z2UI5_CL_SMPE_APP_490` ) ) ).

    t_websocket = VALUE #(
      ( sample( no        = `489`
                title     = `A news feed over WebSocket`
                detail    = `connect, publish, list the active connections - no JavaScript`
                classname = `Z2UI5_CL_SMPE_APP_489` ) ) ).

    t_mime = VALUE #(
      ( sample( no        = `487`
                title     = `Play a sound from the MIME repository`
                detail    = `a success and an error tone, addressed by their ICF path`
                classname = `Z2UI5_CL_SMPE_APP_487` ) ) ).

    t_launchpad = VALUE #(
      ( sample( no        = `481`
                title     = `Read the startup parameters`
                detail    = `what the tile passed in - client->get( )-t_comp_params`
                classname = `Z2UI5_CL_SMPE_APP_481` ) )
      ( sample( no        = `482`
                title     = `Set the shell title`
                detail    = `follow_up_action( cs_event-set_title_launchpad )`
                classname = `Z2UI5_CL_SMPE_APP_482` ) )
      ( sample( no        = `483`
                title     = `Cross-app navigation - sender`
                detail    = `hands two values over to another tile`
                classname = `Z2UI5_CL_SMPE_APP_483` ) )
      ( sample( no        = `484`
                title     = `Cross-app navigation - receiver`
                detail    = `reads them back out of its startup parameters`
                classname = `Z2UI5_CL_SMPE_APP_484` ) ) ).

  ENDMETHOD.

ENDCLASS.
