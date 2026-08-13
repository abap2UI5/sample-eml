"! <p class="shorttext synchronized">abap2UI5 EML sample - shared context</p>
"! Everything the sample apps of this repository do more than once.
"!
"! Built after the abap-util concept: one class, only CLASS-METHODS, `val`
"! in and `result` out, and the constants that belong to the same subject
"! sitting next to the methods that use them.
"!
"! Deliberately small. A sample is read, not reused, so anything that is
"! clearer written out in the app itself stays in the app - the local
"! ty_s_travel structures for instance, which every app declares with just
"! the fields it actually shows.
CLASS z2ui5_cl_smps_context DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    CONSTANTS:
      "! The overall status as the business object stores it - see the
      "! determination setInitialValues and the actions acceptTravel and
      "! rejectTravel in the behavior pools.
      BEGIN OF cs_status,
        open     TYPE string VALUE `O` ##NO_TEXT,
        accepted TYPE string VALUE `A` ##NO_TEXT,
        rejected TYPE string VALUE `X` ##NO_TEXT,
      END OF cs_status.

    "! Collects the messages of a RAP response and shows them in a message box.
    "!
    "! The collecting is not done here: z2ui5_cl_util=>msg_get_collect( )
    "! already recognises a RAP structure by its %MSG / %FAIL components and
    "! reads far more out of it than a hand written loop over %msg would -
    "! the failure cause, the element, the action, %cid and %tky. abap2UI5 is
    "! a mandatory dependency of this repository anyway, so there is nothing
    "! to gain from repeating it.
    "!
    "! @parameter client | the app's client
    "! @parameter val    | a REPORTED response, one of its entity tables, or a FAILED response
    CLASS-METHODS msg_display
      IMPORTING
        client TYPE REF TO z2ui5_if_client
        val    TYPE any.

    "! Translates the stored status into something readable.
    "! @parameter val | OverallStatus as stored, see cs_status
    CLASS-METHODS status_get_text
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    "! The matching sap.m.ObjectStatus state, so the list colours agree
    "! with the text across all apps.
    "! @parameter val | OverallStatus as stored, see cs_status
    CLASS-METHODS status_get_state
      IMPORTING
        val           TYPE any
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smps_context IMPLEMENTATION.

  METHOD msg_display.

    DATA(text) = z2ui5_cl_util=>msg_get_collect( val ).

    " a business object may reject an operation without raising a message -
    " saying so beats an empty popup
    IF text IS INITIAL.
      text = `The operation failed, no further details available`.
    ENDIF.

    client->message_box_display(
        text = text
        type = z2ui5_cl_util=>cs_ui5_msg_type-e ).

  ENDMETHOD.


  METHOD status_get_text.

    result = SWITCH #( val
                       WHEN cs_status-open     THEN `Open`
                       WHEN cs_status-accepted THEN `Accepted`
                       WHEN cs_status-rejected THEN `Rejected`
                       ELSE `` ).

  ENDMETHOD.


  METHOD status_get_state.

    result = SWITCH #( val
                       WHEN cs_status-open     THEN z2ui5_cl_util=>cs_ui5_msg_type-i
                       WHEN cs_status-accepted THEN z2ui5_cl_util=>cs_ui5_msg_type-s
                       WHEN cs_status-rejected THEN z2ui5_cl_util=>cs_ui5_msg_type-e
                       ELSE `None` ).

  ENDMETHOD.

ENDCLASS.
