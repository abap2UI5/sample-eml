CLASS lcl_locking DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_seqg3,
        " Elementary Lock of Lock Entry (Table Name)
        gname    TYPE c LENGTH 30,
        " Argument String (=Key Fields) of Lock Entry
        garg     TYPE c LENGTH 150,
        " Lock Mode (Shared/Exclusive) of a Lock Entry
        gmode    TYPE c LENGTH 1,
        " Lock Owner, ID of Logical Unit of Work (LUW)
        gusr     TYPE c LENGTH 58,
        " Lock Owner, ID of Logical Unit of Work (LUW) / Update Task
        gusrvb   TYPE c LENGTH 58,
        " Cumulative Counter for Lock Entry / Dialog
        guse     TYPE int4,
        " Cumulative Counter for Lock Entry / Update Task
        gusevb   TYPE int4,
        " Name of Lock Object in the Lock Entry
        gobj     TYPE c LENGTH 16,
        " Client in the lock entry
        gclient  TYPE c LENGTH 3,
        " User name in lock entry
        guname   TYPE c LENGTH 12,
        " Argument String of Lock Entry (Table Key Fields)
        gtarg    TYPE c LENGTH 50,
        " Transaction Code in the Lock Entry
        gtcode   TYPE c LENGTH 20,
        " Backup flag for lock entry
        gbcktype TYPE c LENGTH 1,
        " Host Name in the Lock Owner ID
        gthost   TYPE c LENGTH 32,
        " Work Process Number in Lock Owner ID
        gtwp     TYPE n LENGTH 2,
        " SAP System Number in Lock Owner ID
        gtsysnr  TYPE n LENGTH 2,
        " Date within lock owner ID
        gtdate   TYPE d,
        " Time in Lock Owner ID
        gttime   TYPE t,
        " Time/Microseconds Share in Lock Owner ID
        gtusec   TYPE n LENGTH 6,
        " Selection Indicator of Lock Entry
        gtmark   TYPE c LENGTH 1,
        " Cumulative Counter for Lock Entry
        gusetxt  TYPE n LENGTH 10,
        " Cumulative Counter for Lock Entry / Update Task
        gusevbt  TYPE n LENGTH 10,
      END OF ty_seqg3.

    CLASS-METHODS acquire_lock.

    CLASS-METHODS get_lock_counter
      RETURNING
        VALUE(result) TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS lcl_locking IMPLEMENTATION.

  METHOD acquire_lock.

    DATA(lv_fm) = 'ENQUEUE_E_TABLE'.
    CALL FUNCTION lv_fm
      EXPORTING
        tabname        = 'Z2UI5_T_SMPS_01'
        varkey         = 'Z100'
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(error_text).
      RAISE EXCEPTION NEW z2ui5_cx_util_error( val = error_text ).
    ENDIF.

  ENDMETHOD.


  METHOD get_lock_counter.
    DATA enqueue_table TYPE STANDARD TABLE OF ty_seqg3 WITH EMPTY KEY.

    DATA argument TYPE c LENGTH 150.
    argument = |Z2UI5_T_SMPS_01                        Z100*|.

    DATA(lv_fm) = 'ENQUEUE_READ'.
    CALL FUNCTION lv_fm
      EXPORTING
        garg                  = argument
        guname                = sy-uname
      TABLES
        enq                   = enqueue_table
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(error_text).
      RAISE EXCEPTION NEW z2ui5_cx_util_error( val = error_text ).
    ENDIF.

    result = VALUE #( enqueue_table[ 1 ]-gusevb OPTIONAL ).

  ENDMETHOD.

ENDCLASS.
