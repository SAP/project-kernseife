*&---------------------------------------------------------------------*
*& Report s_upload_local_info
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zknsf_classification_managr.

TYPES: BEGIN OF data_type,
         file_id        TYPE sysuuid_x16,
         url            TYPE char140,
         commit_hash    TYPE char40,
         last_git_check TYPE string,
         created        TYPE string,
         data_type      TYPE string,
         source         TYPE char5,
         uploader       TYPE char12,
       END OF data_type.

DATA(class_program) = NEW zknsf_cl_classification_mangr( ) ##NEEDED.

START-OF-SELECTION.
  DATA: db_files   TYPE TABLE OF zknsf_api_header   ##NEEDED,
        columns    TYPE lvc_t_fcat                 ##NEEDED,
        alv_parent TYPE REF TO cl_gui_container    ##NEEDED,
        data_files TYPE TABLE OF cl_ycm_cc_classification_mangr=>api_type ##NEEDED,
        data_file  TYPE cl_ycm_cc_classification_mangr=>api_type          ##NEEDED.


  DATA(alv_grid) = NEW cl_gui_alv_grid( alv_parent ) ##NEEDED.

  TRY.
      data_files = class_program->get_data( ).
    CATCH cx_ycm_cc_provider_error INTO DATA(file_exception) ##NEEDED.
      MESSAGE file_exception->get_text( ) TYPE 'E'.
  ENDTRY.

  columns = VALUE #( (
                       fieldname = 'FILE_ID'
                       coltext   = 'File ID'(001)
                       col_pos   = 1
                       no_out    = 'X' )
                     ( fieldname = 'URL'
                       coltext   = 'File'(010)
                       col_pos   = 2
                       outputlen = 30 )
                     ( fieldname = 'COMMIT_HASH'
                       coltext   = 'Commit Hash'(002)
                       col_pos   = 3
                       outputlen = 10
                       no_out    = 'X' )
                     ( fieldname = 'LAST_GIT_CHECK'
                       coltext   = 'Last Git Check'(003)
                       col_pos   = 4
                       no_out    = 'X'
                       outputlen = 13 )
                     ( fieldname = 'CREATED'
                       coltext   = 'Created'(004)
                       col_pos   = 5
                       outputlen = 16 )
                     ( fieldname = 'DATA_TYPE'
                       coltext   = 'Data Type'(005)
                       col_pos   = 6 )
                     ( fieldname = 'SOURCE'
                       coltext   = 'Source'(006)
                       col_pos   = 7
                       outputlen = 8 )
                     ( fieldname = 'UPLOADER'
                       coltext   = 'Uploader'(011)
                       col_pos   = 8
                       outputlen = 13 ) ) ##NUMBER_OK.

  alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                         CHANGING  it_outtab       = data_files
                                                   it_fieldcatalog = columns ).

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      it_fieldcat_lvc          = columns
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'PF_STATUS_SET'
      i_callback_user_command  = 'USER_COMMAND'
    TABLES
      t_outtab                 = data_files
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

FORM pf_status_set USING rt_extab TYPE slis_t_extab ##NEEDED ##CALLED.
  SET PF-STATUS 'STATUS_001'.
ENDFORM.

FORM user_command USING ucomm LIKE sy-ucomm selfield TYPE slis_selfield RAISING cx_ycm_cc_provider_error ##NEEDED ##CALLED.
  CASE ucomm.
    WHEN 'RELOAD'.
      data_files = class_program->get_data( ).


      alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                             CHANGING  it_outtab       = data_files
                                                       it_fieldcatalog = columns ).

    WHEN 'DELETE'.
      DATA: answer        TYPE char01,
            sel_row_index TYPE TABLE OF lvc_s_row.

      AUTHORITY-CHECK OBJECT 'SYCM_API'
                ID 'ACTVT'     FIELD '06'.

      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '109' ).
      ENDIF.

      alv_grid->get_selected_rows( IMPORTING et_index_rows = sel_row_index ).

      IF sel_row_index IS INITIAL.
        MESSAGE 'No entry selected'(009) TYPE 'E'.
      ELSE.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = 'Delete confirmation'(007)
            text_question         = 'Confirm deletion of the selected files'(008)
            default_button        = '2'
            display_cancel_button = abap_false
          IMPORTING
            answer                = answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        IF answer = '1'.
          LOOP AT sel_row_index ASSIGNING FIELD-SYMBOL(<row>).
            DATA(selected_file) = data_files[ <row>-index ].
            class_program->delete_file( CONV string( selected_file-url ) ).
          ENDLOOP.

          data_files = class_program->get_data( ).

          alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                                 CHANGING  it_outtab       = data_files
                                                           it_fieldcatalog = columns ).
        ENDIF.

      ENDIF.

    WHEN 'UPLOADC'.
      DATA: data_tab        TYPE string_table,
            file_table      TYPE filetable,
            file_name       TYPE string,
            path            TYPE string,
            number_of_files TYPE i.

      AUTHORITY-CHECK OBJECT 'SYCM_API'
                ID 'ACTVT'     FIELD '01'.
      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '110' ).
      ENDIF.

      cl_gui_frontend_services=>file_open_dialog( EXPORTING  file_filter = '.json'
                                                  CHANGING   file_table  = file_table
                                                             rc          = number_of_files
                                                  EXCEPTIONS OTHERS      = 0 ) ##NO_TEXT.

      IF number_of_files <> 1.
        RETURN.
      ENDIF.
      path = file_table[ 1 ]-filename.

      DATA file_separator TYPE c.
      cl_gui_frontend_services=>get_file_separator( CHANGING file_separator = file_separator ).
      SPLIT path AT file_separator INTO TABLE DATA(parts).
      file_name = parts[ lines( parts ) ].

      IF ucomm = 'UPLOADC'.
        DATA(file_type) = zknsf_cl_classification_mangr=>ty_custom_file_type-kernseife_custom.
      ENDIF.

      cl_gui_frontend_services=>gui_upload( EXPORTING  filename = path
                                            CHANGING   data_tab = data_tab
                                            EXCEPTIONS OTHERS   = 1 ).

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      TRY.
          class_program->upload_custom_file( file_content = data_tab
                                             file_name    = file_name
                                             file_type    = file_type
                                             uploader     = sy-uname ).

          data_files = class_program->get_data( ).

          alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                                 CHANGING  it_outtab       = data_files
                                                           it_fieldcatalog = columns ).

        CATCH cx_ycm_cc_provider_error INTO DATA(file_exception).
          MESSAGE file_exception->get_text( ) TYPE 'E'.
      ENDTRY.
  ENDCASE.

ENDFORM.
