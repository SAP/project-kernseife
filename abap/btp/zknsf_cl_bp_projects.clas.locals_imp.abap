CLASS lhc_project DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    METHODS setup_finish IMPORTING p_task TYPE c.
    METHODS run_atc_finish IMPORTING p_task TYPE c.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR project RESULT result.

    METHODS setup FOR MODIFY
      IMPORTING keys FOR ACTION project~setup.


    METHODS uploadfile FOR MODIFY
      IMPORTING keys FOR ACTION project~uploadfile.
    METHODS runatc FOR MODIFY
      IMPORTING keys FOR ACTION project~runatc.




    DATA: setup_message TYPE string.
    DATA: setup_finished TYPE abap_boolean.
    DATA: setup_error TYPE abap_boolean.

    DATA: run_atc_message TYPE string.
    DATA: run_atc_error TYPE abap_boolean.
    DATA: run_atc_finished TYPE abap_boolean.
ENDCLASS.

CLASS lhc_project IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD setup.
    " Check if there is already a Custom Code Migration Project
    SELECT SINGLE  description FROM zknsf_i_projects INTO @DATA(description).
    IF sy-subrc EQ 0 AND description IS NOT INITIAL.
      " Error => already exists
      reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-warning text = |Kernseife Project already exists| ) ) ).
      RETURN.
    ENDIF.

    setup_finished = abap_false.
    CALL FUNCTION 'ZKNSF_CREATE_PROJECT' STARTING NEW TASK 'ZKNSF_SETUP'
      DESTINATION 'NONE'
      CALLING setup_finish ON END OF TASK.

    WAIT FOR ASYNCHRONOUS TASKS UNTIL setup_finished EQ abap_true.

    IF setup_error IS NOT INITIAL.
      reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-error text = |Failed: {  setup_message }| ) ) ).
      RETURN.
    ENDIF.

    reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-success text = |Project created| ) ) ).
  ENDMETHOD.

  METHOD setup_finish.

    RECEIVE RESULTS FROM FUNCTION 'ZKNSF_CREATE_PROJECT'
       IMPORTING
         e_message = setup_message
         e_error = setup_error.
    setup_finished = abap_true.
  ENDMETHOD.


  METHOD uploadfile.
    DATA message TYPE string.
    DATA(classification_manager) = NEW zknsf_cl_classification_mangr( ).

    " Upload File
    DATA(file_content) = VALUE #( keys[ 1 ]-%param-_streamproperties-streamproperty OPTIONAL ).
    DATA(file_name) = VALUE #( keys[ 1 ]-%param-_streamproperties-filename OPTIONAL ).
    DATA(file_type) = zknsf_cl_classification_mangr=>ty_custom_file_type-kernseife_custom.

    DATA(zip) = NEW cl_abap_zip( ).

    zip->load( file_content ).

    IF lines( zip->files ) <> 1.
      MESSAGE ID 'ZKNSF' TYPE 'E' NUMBER 001 INTO message.
      RETURN.
    ENDIF.
    IF NOT zip->files[ 1 ]-name CP '*.json'.
      MESSAGE ID 'ZKNSF' TYPE 'E' NUMBER 001 INTO message.
    ENDIF.

    zip->get( EXPORTING name    = zip->files[ 1 ]-name
              IMPORTING content = file_content ).


    TRY.
        " Now delete existing files
        DATA(api_files) = classification_manager->get_api_files( ).
        LOOP AT api_files ASSIGNING FIELD-SYMBOL(<api_file>).
          classification_manager->delete_file( url = CONV string( <api_file>-url ) ).
        ENDLOOP.

        " Then add the new ones
        classification_manager->upload_custom_file( file_content = file_content
                                                    file_name    = CONV string( file_name )
                                                    file_type    = file_type
                                                    uploader     = sy-uname ).
      CATCH cx_root INTO DATA(root_exception).
          reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-error text = |Failed: {  root_exception->get_text( ) }| ) ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD runatc.

    run_atc_finished = abap_false.
    CALL FUNCTION 'ZKNSF_RUN_ATC' STARTING NEW TASK 'ZKNSF_ATC'
      DESTINATION 'NONE'
      CALLING run_atc_finish ON END OF TASK.

    WAIT FOR ASYNCHRONOUS TASKS UNTIL run_atc_finished EQ abap_true.

    IF run_atc_error IS NOT INITIAL.
      reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-error text = |Failed: {  run_atc_message }| ) ) ).
      RETURN.
    ENDIF.

    reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-success text = |Success: Started ATC Run| ) ) ).
  ENDMETHOD.

  METHOD run_atc_finish.

    RECEIVE RESULTS FROM FUNCTION 'ZKNSF_RUN_ATC'
       IMPORTING
         e_message = run_atc_message
         e_error = run_atc_error.
    run_atc_finished = abap_true.
  ENDMETHOD.


ENDCLASS.
