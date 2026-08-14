CLASS z2ui5_cl_smps_app_313 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_row,
        count      TYPE i,
        value      TYPE string,
        descr      TYPE string,
        icon       TYPE string,
        info       TYPE string,
        checkbox   TYPE abap_bool,
        percentage TYPE p LENGTH 5 DECIMALS 2,
        valuecolor TYPE string,
      END OF ty_s_row.
    DATA t_tab TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    DATA check_ui5 TYPE abap_bool.
    DATA mv_key TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smps_app_313 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    IF client->check_on_init( ).

      " An earlier revision of this app ran the same two smart controls against
      " the BookingSupplement entity of /sap/opu/odata/DMO/API_TRAVEL_U_V2/. It
      " was kept here commented out and is gone with the move to
      " z2ui5_cl_ui5_view_builder - the service and entity set are the only part
      " of it that was not already in the code below.

      DATA(view) = z2ui5_cl_ui5_view_builder=>factory( )->ele( n = `View` ns = `mvc`
          )->a( n = `displayBlock`         v = `true`
          )->a( n = `height`               v = `100%`
          )->a( n = `xmlns`                v = `sap.m`
          )->a( n = `xmlns:mvc`            v = `sap.ui.core.mvc`
          )->a( n = `xmlns:core`           v = `sap.ui.core`
          )->a( n = `xmlns:smartFilterBar` v = `sap.ui.comp.smartfilterbar`
          )->a( n = `xmlns:smartTable`     v = `sap.ui.comp.smarttable` ).

      DATA(page) = view->ele( `Shell` )->ele( `Page`
              )->a( n = `title`          v = `abap2UI5 - Smart Controls with Variants`
              )->a( n = `showNavButton`  b = client->check_app_prev_stack( )
              )->a( n = `navButtonPress` v = client->_event_nav_app_leave( ) ).

      page->ele( n = `SmartFilterBar` ns = `smartFilterBar`
          )->a( n = `id`             v = `smartFilterBar`
          )->a( n = `entitySet`      v = `ProductType_2`
          )->a( n = `persistencyKey` v = `SmartFilterPKey` )->ele( n = `controlConfiguration` ns = `smartFilterBar`
          )->tag( n = `ControlConfiguration` ns = `smartFilterBar`
              )->a( n = `key`                                      v = `ProductType`
              )->a( n = `visibleInAdvancedArea`                    b = abap_true
              )->a( n = `preventInitialDataFetchInValueHelpDialog` b = abap_false )->end( )->ele( n = `SmartTable` ns = `smartTable`
            )->a( n = `id`                      v = `smartFiltertable`
            )->a( n = `smartFilterId`           v = `smartFilterBar`
            )->a( n = `tableType`               v = `ResponsiveTable`
            )->a( n = `editable`                b = abap_false
            )->a( n = `initiallyVisibleFields`  v = `ProductType,ProductType_Text`
            )->a( n = `entitySet`               v = `ProductType_2`
            )->a( n = `useVariantManagement`    b = abap_true
            )->a( n = `useExportToExcel`        b = abap_true
            )->a( n = `useTablePersonalisation` b = abap_true
            )->a( n = `header`                  v = `Test`
            )->a( n = `showRowCount`            b = abap_true
            )->a( n = `enableExport`            b = abap_false
            )->a( n = `enableAutoBinding`       b = abap_false ).

      client->view_display( val                       = view->stringify( )
                            switch_default_model_path = `/sap/opu/odata/sap/UI_PRODUCTLIST/` ).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
