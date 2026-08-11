CLASS lhc_ticket DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Ticket
      RESULT result.

    METHODS manageadmin FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Ticket~manageAdmin.
ENDCLASS.

CLASS lhc_ticket IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD manageadmin.
    READ ENTITIES OF z2ui5_r_smpe_tck IN LOCAL MODE
      ENTITY Ticket
        FIELDS ( CreatedAt ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_tickets).

    DATA lv_now TYPE timestampl.
    GET TIME STAMP FIELD lv_now.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    " Always maintain change data
    MODIFY ENTITIES OF z2ui5_r_smpe_tck IN LOCAL MODE
      ENTITY Ticket
        UPDATE FIELDS ( ChangedBy LastChangedAt LocalLastChangedAt )
        WITH VALUE #( FOR t IN lt_tickets (
                        %tky               = t-%tky
                        ChangedBy          = lv_user
                        LastChangedAt      = lv_now
                        LocalLastChangedAt = lv_now ) ).

    " Set creation data only where still initial (i.e. on create)
    MODIFY ENTITIES OF z2ui5_r_smpe_tck IN LOCAL MODE
      ENTITY Ticket
        UPDATE FIELDS ( CreatedBy CreatedAt )
        WITH VALUE #( FOR t IN lt_tickets WHERE ( CreatedAt IS INITIAL ) (
                        %tky      = t-%tky
                        CreatedBy = lv_user
                        CreatedAt = lv_now ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ticket DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_ticket IMPLEMENTATION.

  METHOD save_modified.
    " ---- Notification event: fired on CREATE (carries key only) ----
    IF create-ticket IS NOT INITIAL.
      RAISE ENTITY EVENT z2ui5_r_smpe_tck~TicketCreated
        FROM VALUE #( FOR c IN create-ticket (
                        %key = VALUE #( TicketUUID = c-TicketUUID ) ) ).
    ENDIF.

    " ---- Data event: fired on UPDATE (carries enriched payload) ----
    IF update-ticket IS NOT INITIAL.
      READ ENTITIES OF z2ui5_r_smpe_tck IN LOCAL MODE
        ENTITY Ticket
          FIELDS ( Title Priority Status ChangedBy LastChangedAt )
          WITH CORRESPONDING #( update-ticket )
          RESULT DATA(lt_current).

      RAISE ENTITY EVENT z2ui5_r_smpe_tck~StatusChanged
        FROM VALUE #( FOR t IN lt_current (
                        %key   = VALUE #( TicketUUID = t-TicketUUID )
                        %param = VALUE #( Title     = t-Title
                                          Priority  = t-Priority
                                          Status    = t-Status
                                          ChangedBy = t-ChangedBy
                                          ChangedAt = t-LastChangedAt ) ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
