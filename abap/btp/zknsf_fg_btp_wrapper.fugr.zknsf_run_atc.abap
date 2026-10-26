FUNCTION zknsf_run_atc.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(E_MESSAGE) TYPE  STRING
*"     VALUE(E_ERROR) TYPE  ABAP_BOOLEAN
*"----------------------------------------------------------------------
  CLEAR e_message.
  CLEAR e_error.

  TRY.
      DATA(transaction_manager) =
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager(  ).
      transaction_manager->set_transaction_context( iv_enqueue_scope = /bobf/if_conf_c=>sc_enqueue_scope_dialog ).


      DATA(service_manager) =
        /bobf/cl_tra_serv_mgr_factory=>get_service_manager(
        iv_bo_key = if_sycm_aps_i_project_c=>sc_bo_key ).


      SELECT SINGLE projectid FROM zknsf_i_projects INTO @DATA(project_id).
      IF sy-subrc <> 0.
        " No Project exists!
        e_message = |Failed: No Project Exists|.
        e_error = abap_true.
        RETURN.
      ENDIF.


      DATA key_table TYPE /bobf/t_frw_key.
      APPEND VALUE /bobf/s_frw_key( key = project_id ) TO key_table.

      DATA(object_configuration) =
        /bobf/cl_frw_factory=>get_configuration(
        if_sycm_aps_i_project_c=>sc_bo_key
        ).


      service_manager->do_action( EXPORTING iv_act_key = if_sycm_aps_i_project_c=>sc_action-sycm_aps_i_project-run_atc
                                            it_key     = key_table
                                  IMPORTING eo_message = DATA(messages)
                                            et_failed_key = DATA(failed_keys) ).

      DATA(has_errors) = xsdbool( failed_keys IS NOT INITIAL ).
      IF messages IS BOUND AND messages->check( ) = abap_true.
        has_errors = abap_true.
      ENDIF.

      IF has_errors = abap_true.
        e_error = abap_true.
        e_message = |ATC scheduling action failed|.
        IF messages IS BOUND.
          messages->get( IMPORTING et_message = DATA(message_table) ).
          IF lines( message_table ) > 0.
            CLEAR e_message.
            LOOP AT message_table INTO DATA(message).
              IF e_message IS INITIAL.
                e_message = message->get_text( ).
              ELSE.
                e_message = |{ e_message }; { message->get_text( ) }|.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.
        RETURN.
      ENDIF.


    CATCH cx_root INTO DATA(exception_root).
      e_message = exception_root->get_text( ).
      e_error = abap_true.
      RETURN.
  ENDTRY.


ENDFUNCTION.
