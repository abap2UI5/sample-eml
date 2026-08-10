CLASS z2ui5_cl_smpe_d_save DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_draft,
        travel_uuid TYPE string,
        travel_id   TYPE string,
        description TYPE string,
      END OF ty_s_draft.
    DATA t_drafts TYPE STANDARD TABLE OF ty_s_draft WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS data_read.
    METHODS draft_save.
    METHODS view_display.

    METHODS messages_display
      IMPORTING
        t_reported TYPE ANY TABLE.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpe_d_save IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      data_read( ).
      view_display( ).
    ELSEIF client->check_on_event( `SAVE` ).
      draft_save( ).
    ENDIF.

  ENDMETHOD.


  METHOD draft_save.

    DATA(uuid) = client->get_event_arg( 1 ).
    DATA(s_draft) = t_drafts[ travel_uuid = uuid ].

    " An ordinary UPDATE - the only thing that makes it a draft update is
    " %is_draft = mk-on in the key. The active instance stays untouched.
    MODIFY ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        UPDATE FIELDS ( description )
        WITH VALUE #( ( %tky        = VALUE #( traveluuid = uuid
                                               %is_draft  = if_abap_behv=>mk-on )
                        description = s_draft-description ) )
      FAILED DATA(s_failed)
      REPORTED DATA(s_reported).

    IF s_failed-travel IS NOT INITIAL.

      ROLLBACK ENTITIES.
      messages_display( s_reported-travel ).
      RETURN.

    ENDIF.

    " The COMMIT writes the draft into the draft table z2ui5_d_smpe_trd.
    " Note what does NOT happen here: no validation runs. A draft may be
    " incomplete or plainly wrong and still be saved - it survives the
    " session and even a logoff. The validations wait for Activate.
    COMMIT ENTITIES RESPONSE OF z2ui5_r_smpe_trd
      FAILED DATA(s_failed_commit)
      REPORTED DATA(s_reported_commit).

    IF s_failed_commit IS NOT INITIAL.

      messages_display( s_reported_commit-travel ).
      RETURN.

    ENDIF.

    data_read( ).
    client->view_model_update( ).
    client->message_toast_display( |Draft of travel { s_draft-travel_id } saved - it survives a logoff| ).

  ENDMETHOD.


  METHOD data_read.

    SELECT FROM z2ui5_r_smpe_trd
      FIELDS TravelUuid
      ORDER BY TravelId
      INTO TABLE @DATA(t_result)
      UP TO 20 ROWS.

    " read the DRAFT instances, not the active ones - so the form below
    " shows what is currently in the draft, which is what gets changed
    READ ENTITIES OF z2ui5_r_smpe_trd
      ENTITY travel
        FIELDS ( travelid description ) WITH VALUE #( FOR s_row IN t_result
                                                      ( %tky = VALUE #( traveluuid = s_row-traveluuid
                                                                        %is_draft  = if_abap_behv=>mk-on ) ) )
      RESULT DATA(t_result_drafts)
      FAILED DATA(s_failed).

    t_drafts = VALUE #( FOR s_result IN t_result_drafts
        ( travel_uuid = |{ s_result-traveluuid }|
          travel_id   = |{ s_result-travelid ALPHA = OUT }|
          description = |{ s_result-description }| ) ).

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
            title          = `abap2UI5 - EML - Change and Save a Draft`
            navbuttonpress = client->_event_nav_app_leave( )
            shownavbutton  = client->check_app_prev_stack( ) ).

    page->message_strip(
        text = `Only travels that already have a draft show up here - create one with the Enter Draft Mode app.`
        type = `Information` ).

    DATA(table) = page->table( client->_bind( t_drafts ) ).

    table->header_toolbar( )->toolbar(
        )->title( `UPDATE ... WITH %is_draft = mk-on` ).

    table->columns(
        )->column( )->text( `ID` )->get_parent(
        )->column( )->text( `Description (draft)` )->get_parent(
        )->column( )->text( `` ).

    table->items( )->column_list_item(
        )->cells(
            )->text( `{TRAVEL_ID}`
            )->input( `{DESCRIPTION}`
            )->button(
                text  = `Save Draft`
                press = client->_event( val   = `SAVE`
                                        t_arg = VALUE #( ( `${TRAVEL_UUID}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
