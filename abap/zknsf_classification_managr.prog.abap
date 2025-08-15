*&---------------------------------------------------------------------*
*& Report s_upload_local_info
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zknsf_classification_managr.
DATA:
  alv_grid              TYPE REF TO cl_gui_alv_grid,
  api_alv_grid          TYPE REF TO cl_gui_alv_grid,
  scsr_alv_grid         TYPE REF TO cl_gui_alv_grid,
  new_file_name         TYPE string,
  obj_type              TYPE string,
  obj_key               TYPE string,
  scsr_obj_type         TYPE string,
  scsr_obj_key          TYPE string,
  trac_cons             TYPE abap_bool,
  data_files            TYPE TABLE OF cl_ycm_cc_cache_write_api=>ty_api_file,
  data_files_full_names TYPE TABLE OF cl_ycm_cc_cache_write_api=>ty_api_file,
  selected_row          TYPE lvc_t_row,
  selected_row_api      TYPE lvc_t_row,
  selected_file         TYPE cl_ycm_cc_cache_write_api=>ty_api_file,
  selected_api          TYPE cl_ycm_cc_cache_write_api=>ty_api.


DATA(class_program) = NEW zknsf_cl_classification_mangr( ).
DATA(writer) = NEW zknsf_cl_cache_write_api( ).

CLASS classification_manager DEFINITION FINAL.
  PUBLIC SECTION.
    DATA:
      columns        TYPE lvc_t_fcat,
      api_columns    TYPE lvc_t_fcat,
      scsr_columns   TYPE lvc_t_fcat,
      api_data_files TYPE TABLE OF cl_ycm_cc_cache_write_api=>ty_api.

    METHODS: constructor,
      display_main_alv,
      display_detail_alv,
      get_apis RETURNING VALUE(result) TYPE cl_ycm_cc_cache_write_api=>apis,
      user_command_in_file_overview IMPORTING ucomm TYPE sy-ucomm,
      user_command_in_api_overview IMPORTING api_ucomm TYPE sy-ucomm
                                   RAISING   cx_ycm_cc_provider_error,
      user_command_in_scsr_overview IMPORTING scsr_ucomm TYPE sy-ucomm,
      handle_double_click_in_100 FOR EVENT double_click OF cl_gui_alv_grid IMPORTING e_row,
      handle_double_click_in_200 FOR EVENT double_click OF cl_gui_alv_grid IMPORTING e_row,
      display_successor_alv.
  PRIVATE SECTION.

    METHODS get_successors
      RETURNING
        VALUE(result) TYPE cl_ycm_cc_cache_write_api=>successors.
    METHODS export_json
      IMPORTING
        file_name       TYPE string
        content_as_json TYPE string.

ENDCLASS.

CLASS classification_manager IMPLEMENTATION.
  METHOD constructor.
    DATA(alv_parent) = NEW cl_gui_custom_container( 'CUSTOM_CONTROL' ).
    alv_grid = NEW cl_gui_alv_grid( alv_parent ).

    DATA(api_alv_parent) = NEW cl_gui_custom_container( 'SECOND_CUSTOM_CONTROL' ).
    api_alv_grid = NEW cl_gui_alv_grid( api_alv_parent ).

    DATA(scsr_alv_parent) = NEW cl_gui_custom_container( 'SUCCESSOR_C_CONTROL' ).
    scsr_alv_grid = NEW cl_gui_alv_grid( scsr_alv_parent ).

    SET HANDLER handle_double_click_in_100 FOR alv_grid.
    SET HANDLER handle_double_click_in_200 FOR api_alv_grid.

  ENDMETHOD.

  METHOD display_main_alv.
    DATA: db_timestamp    TYPE timestamp,
          local_timestamp TYPE timestamp.

    TRY.
        data_files = class_program->get_api_files( ).
      CATCH cx_ycm_cc_provider_error INTO DATA(file_exception).
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
                         outputlen = 55 )
                       ( fieldname = 'ETAG'
                         coltext   = 'ETag'(002)
                         col_pos   = 3
                         outputlen = 10
                         no_out    = 'X' )
                       ( fieldname = 'DATA_TYPE'
                         coltext   = 'Data Type'(005)
                         col_pos   = 5 )
                       ( fieldname = 'SOURCE'
                         coltext   = 'Source'(006)
                         col_pos   = 6
                         outputlen = 8 )
                       ( fieldname = 'UPLOADER'
                         coltext   = 'Uploader'(011)
                         col_pos   = 7
                         outputlen = 13 )
                       ( fieldname = 'CREATED'
                         coltext   = 'Created'(004)
                         col_pos   = 8
                         outputlen = 16 ) ) ##NUMBER_OK.

    TRY.


        DATA(lt_sort) =  VALUE lvc_t_sort(
                                          ( fieldname = 'DATA_TYPE'
                                            down      = 'X' )
                                          ( fieldname = 'URL'
                                            up        = 'X' )
                                         ).

        data_files_full_names = data_files.
        LOOP AT data_files ASSIGNING FIELD-SYMBOL(<file>).
          db_timestamp = <file>-created.
          CONVERT TIME STAMP db_timestamp TIME ZONE sy-zonlo
          INTO DATE DATA(dat) TIME DATA(tim).

          CONCATENATE dat tim INTO DATA(timestamp_str).
          local_timestamp = timestamp_str ##INTENTIONAL_NON_UTC.

          <file>-created = |{ local_timestamp TIMESTAMP = ENVIRONMENT }|.
        ENDLOOP.

        SORT data_files BY
          data_type DESCENDING
          url ASCENDING.

        alv_grid->set_table_for_first_display(
          EXPORTING
            is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
          CHANGING
            it_fieldcatalog = columns
            it_outtab       = data_files
            it_sort         = lt_sort
        ).

      CATCH cx_ycm_cc_provider_error INTO DATA(alv_exception).
        MESSAGE alv_exception->get_text( ) TYPE 'E'.
    ENDTRY.

    alv_grid->refresh_table_display( ).
  ENDMETHOD.

  METHOD display_detail_alv.
    api_data_files = get_apis( ).

    api_columns = VALUE #( (
                           fieldname = 'API_ID'
                           coltext   = 'API ID'(013)
                           no_out    = 'X'
                           col_pos   = 1 )
                           (
                           fieldname = 'FILE_ID'
                           coltext   = 'File ID'(001)
                           no_out    = 'X'
                           col_pos   = 2 )
                           (
                           fieldname = 'TADIR_OBJECT'
                           coltext   = 'Tadir Object'(014)
                           no_out    = 'X'
                           col_pos   = 3 )
                           (
                           fieldname = 'TADIR_OBJ_NAME'
                           coltext   = 'Tadir Object Name'(015)
                           no_out    = 'X'
                           col_pos   = 4 )
                           (
                           fieldname = 'OBJECT_TYPE'
                           coltext   = 'Object Type'(016)
                           col_pos   = 5 )
                           (
                           fieldname = 'OBJECT_KEY'
                           coltext   = 'Object Key'(017)
                           col_pos   = 6
                           outputlen = 30 )
                           (
                           fieldname = 'SOFTWARE_COMPONENT'
                           coltext   = 'Software Component'(018)
                           col_pos   = 7
                           outputlen = 15 )
                           (
                           fieldname = 'APPLICATION_COMPONENT'
                           coltext   = 'Application Component'(019)
                           col_pos   = 8
                           outputlen = 18 )
                           (
                           fieldname = 'STATE'
                           coltext   = 'Rating'(020)
                           col_pos   = 9
                           outputlen = 30 )
                           (
                           fieldname = 'LABELS'
                           coltext   = 'Labels'(021)
                           col_pos   = 10
                           outputlen = 28 )
                           (
                           fieldname = 'SUCCESSORS'
                           coltext   = 'Successors'(022)
                           col_pos   = 11 ) ) ##NUMBER_OK.

    SELECT * FROM zknsf_api_header WHERE file_id = @selected_file-file_id INTO TABLE @DATA(db_api_file).


    LOOP AT selected_row ASSIGNING FIELD-SYMBOL(<sel_row_title>).
      DATA(file_title) = selected_file-url.
      DATA(layout) = VALUE lvc_s_layo( sel_mode = 'A' grid_title = file_title ).
    ENDLOOP.


    api_alv_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = layout
      CHANGING
        it_fieldcatalog = api_columns
        it_outtab       = api_data_files
    ).

    api_alv_grid->refresh_table_display( ).
  ENDMETHOD.

  METHOD display_successor_alv.
    DATA: scsr_data    TYPE cl_ycm_cc_cache_write_api=>successors,
          selected_api TYPE cl_ycm_cc_cache_write_api=>ty_api.

    scsr_columns = VALUE #( (
                            fieldname = 'API_ID'
                            coltext   = 'API ID'(013)
                            no_out    = 'X'
                            col_pos   = 1 )
                            (
                            fieldname = 'TADIR_OBJECT'
                            coltext   = 'Tadir Object'(014)
                            no_out    = 'X'
                            col_pos   = 3 )
                            (
                            fieldname = 'TADIR_OBJ_NAME'
                            coltext   = 'Tadir Object Name'(015)
                            no_out    = 'X'
                            col_pos   = 4 )
                            (
                            fieldname = 'OBJECT_TYPE'
                            coltext   = 'Object Type'(016)
                            col_pos   = 5 )
                            (
                            fieldname = 'OBJECT_KEY'
                            coltext   = 'Object Key'(017)
                            col_pos   = 6
                            outputlen = 30 ) ) ##NUMBER_OK.

    scsr_data = get_successors( ).

    LOOP AT selected_row ASSIGNING FIELD-SYMBOL(<sel_row_title>).
      selected_api = api_data_files[ selected_row_api[ 1 ]-index ].
    ENDLOOP.

    scsr_alv_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = VALUE lvc_s_layo( sel_mode = 'A' grid_title = 'Successors of'(033) && ` ` && selected_api-object_key )
      CHANGING
        it_fieldcatalog = scsr_columns
        it_outtab       = scsr_data
    ).

    scsr_alv_grid->refresh_table_display( ).
  ENDMETHOD.

  METHOD get_apis.
    TRY.
        LOOP AT selected_row ASSIGNING FIELD-SYMBOL(<sel_row>).
          selected_file = data_files[ <sel_row>-index ].
          selected_file = data_files_full_names[ file_id = selected_file-file_id ].
        ENDLOOP.
        result = class_program->get_apis( selected_file-file_id ).

      CATCH cx_ycm_cc_provider_error INTO DATA(api_file_exception).
        MESSAGE api_file_exception->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD get_successors.

    TRY.
        selected_api = api_data_files[ selected_row_api[ 1 ]-index ].
        result = class_program->get_successors( selected_api-api_id ).

      CATCH cx_ycm_cc_provider_error INTO DATA(api_file_exception).
        MESSAGE api_file_exception->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD user_command_in_file_overview.

    CASE ucomm.
      WHEN 'BACK'.
        LEAVE PROGRAM.

      WHEN 'RELOAD'.

        TRY.
            data_files = class_program->get_api_files( ).
          CATCH cx_ycm_cc_provider_error INTO DATA(reload_file_exception).
            MESSAGE reload_file_exception->get_text( ) TYPE 'E'.
        ENDTRY.

        alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                               CHANGING  it_outtab       = data_files
                                                         it_fieldcatalog = columns ).

      WHEN 'DELETE'.
        DATA: answer        TYPE char01.

        alv_grid->get_selected_rows( IMPORTING et_index_rows = selected_row ).

        IF selected_row IS INITIAL.
          MESSAGE 'No entry selected'(009) TYPE 'E'.
        ELSE.

          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar              = 'Delete confirmation'(007)
              text_question         = 'Confirm deletion of the selected file(s)'(008)
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
            TRY.
                LOOP AT selected_row ASSIGNING FIELD-SYMBOL(<row>).
                  selected_file = data_files[ <row>-index ].
                  selected_file = data_files_full_names[ file_id = selected_file-file_id ].
                  class_program->delete_file( CONV string( selected_file-url ) ).
                ENDLOOP.

                data_files = class_program->get_api_files( ).

              CATCH cx_ycm_cc_provider_error INTO DATA(delete_file_exception).
                MESSAGE delete_file_exception->get_text( ) TYPE 'E'.
            ENDTRY.

            alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                                   CHANGING  it_outtab       = data_files
                                                             it_fieldcatalog = columns ).

          ENDIF.

        ENDIF.

      WHEN 'UPLOAD'.
        DATA: data_tab        TYPE string_table,
              file_table      TYPE filetable,
              file_name       TYPE string,
              path            TYPE string,
              answer_upl      TYPE char01,
              number_of_files TYPE i.

        " Check if there is already a file
        TRY.
            DATA(api_files) = class_program->get_api_files( ).
            IF lines( api_files ) > 0.
              " Ask to delete existing
              CALL FUNCTION 'POPUP_TO_CONFIRM'
                EXPORTING
                  titlebar              = 'Delete confirmation'(007)
                  text_question         = 'Confirm to overwrite existing file(s)'(050)
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

              IF answer <> '1'.
                RETURN.
              ENDIF.
            ENDIF.
          CATCH cx_ycm_cc_provider_error.
            MESSAGE reload_file_exception->get_text( ) TYPE 'E'.
        ENDTRY.

        DATA(file_type) = zknsf_cl_classification_mangr=>ty_custom_file_type-kernseife_custom.


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

        cl_gui_frontend_services=>gui_upload( EXPORTING  filename = path
                                              CHANGING   data_tab = data_tab
                                              EXCEPTIONS OTHERS   = 1 ).

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.



        TRY.
            " Now delete existing files
            LOOP AT api_files ASSIGNING FIELD-SYMBOL(<api_file>).
              class_program->delete_file( CONV string( <api_file>-url ) ).
            ENDLOOP.

            " Then add the new ones
            class_program->upload_custom_file( file_content = data_tab
                                               file_name    = file_name
                                               file_type    = file_type
                                               uploader     = sy-uname ).

            data_files = class_program->get_api_files( ).

            alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                                   CHANGING  it_outtab       = data_files
                                                             it_fieldcatalog = columns ).

          CATCH cx_ycm_cc_provider_error INTO DATA(upload_file_exception).
            MESSAGE upload_file_exception->get_text( ) TYPE 'E'.
        ENDTRY.

      WHEN 'CONTENT'.
        alv_grid->get_selected_rows( IMPORTING et_index_rows = selected_row ).

        IF selected_row IS INITIAL.
          MESSAGE 'No entry selected'(009) TYPE 'E'.
        ELSEIF lines( selected_row ) > 1.
          MESSAGE 'More than one entry selected'(012) TYPE 'E'.
        ELSE.
          CALL SCREEN 200.
        ENDIF.

      WHEN 'EXPORT'.
        alv_grid->get_selected_rows( IMPORTING et_index_rows = selected_row ).

        IF selected_row IS INITIAL.
          MESSAGE 'No entry selected'(009) TYPE 'E'.
          RETURN.
        ELSEIF lines( selected_row ) > 1.
          MESSAGE 'More than one entry selected'(012) TYPE 'E'.
          RETURN.
        ENDIF.

        TRY.
            selected_file = data_files[ selected_row[ 1 ]-index ].
          CATCH cx_ycm_cc_provider_error INTO DATA(export_file_exception).
            MESSAGE export_file_exception->get_text( ) TYPE 'E'.
            RETURN.
        ENDTRY.

        SELECT SINGLE data_type, source FROM zknsf_api_header INTO @DATA(api_db) WHERE file_id = @selected_file-file_id.

        IF api_db-data_type <> zknsf_cl_cache_write_api=>co_data_type_custom.
          MESSAGE 'Only local Kernseife files can be exported'(032) TYPE 'E'.
          RETURN.
        ENDIF.
        TRY.
            DATA(content_as_json) = class_program->get_custom_api_file_as_json( selected_file-file_id ).
            export_json( content_as_json = content_as_json file_name = CONV #( selected_file-url ) ).
          CATCH cx_ycm_cc_provider_error INTO export_file_exception.
            MESSAGE export_file_exception->get_text( ) TYPE 'E'.
            RETURN.
        ENDTRY.
    ENDCASE.
  ENDMETHOD.

  METHOD user_command_in_api_overview.
    DATA: answer        TYPE char01,
          sel_row_index TYPE lvc_t_row.

    CASE api_ucomm.
      WHEN 'BACK'.
        CLEAR selected_row.
        alv_grid->set_selected_rows( it_index_rows = selected_row ).
        CALL SCREEN 100.

      WHEN 'RELOAD'.
        api_data_files = get_apis( ).

        api_alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                                   CHANGING  it_outtab       = api_data_files
                                                             it_fieldcatalog = api_columns ).
        api_alv_grid->refresh_table_display( ).

      WHEN 'DELETE'.
        CLEAR sel_row_index.
        api_alv_grid->get_selected_rows( IMPORTING et_index_rows = sel_row_index ).

        IF sel_row_index IS INITIAL.
          MESSAGE 'No entry selected'(009) TYPE 'E'.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar              = 'Delete confirmation'(007)
              text_question         = 'Confirm deletion of the selected api(s)'(023)
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
            TRY.
                DATA(apis) = class_program->get_apis( selected_file-file_id ).

                LOOP AT sel_row_index ASSIGNING FIELD-SYMBOL(<api_row>).
                  DATA(selected_api) = apis[ <api_row>-index ].
                  class_program->delete_api( selected_api-api_id ).
                ENDLOOP.

              CATCH cx_ycm_cc_provider_error INTO DATA(delete_api_exception).
                MESSAGE delete_api_exception->get_text( ) TYPE 'E'.
            ENDTRY.

            api_data_files = get_apis( ).
            api_alv_grid->set_table_for_first_display( EXPORTING is_layout       = VALUE lvc_s_layo( sel_mode = 'A' )
                                                       CHANGING  it_outtab       = api_data_files
                                                                 it_fieldcatalog = api_columns ).

          ENDIF.
        ENDIF.

      WHEN 'DETAIL_API'.
        api_alv_grid->get_selected_rows( IMPORTING et_index_rows = selected_row_api ).

        IF selected_row_api IS INITIAL.
          MESSAGE 'No entry selected'(009) TYPE 'E'.
        ELSEIF lines( selected_row_api ) > 1.
          MESSAGE 'More than one entry selected'(012) TYPE 'E'.
        ELSE.
          CALL SCREEN 500.
        ENDIF.
      WHEN 'EXPORT'.
        SELECT SINGLE data_type, source FROM zknsf_api_header INTO @DATA(api_db) WHERE file_id = @selected_file-file_id.

        IF api_db-data_type <> zknsf_cl_cache_write_api=>co_data_type_custom.
          MESSAGE TEXT-032 TYPE 'E'.
          RETURN.
        ENDIF.

        TRY.
            DATA(content_as_json) = class_program->get_custom_api_file_as_json( selected_file-file_id ).
            export_json( content_as_json = content_as_json file_name = CONV #( selected_file-url ) ).
          CATCH cx_ycm_cc_provider_error INTO DATA(exception).
            MESSAGE exception->get_text( ) TYPE 'E'.
            RETURN.
        ENDTRY.
    ENDCASE.
  ENDMETHOD.

  METHOD export_json.
    DATA user_input_filename TYPE string.
    DATA file_path TYPE string.
    DATA fullpath TYPE string.
    DATA user_action TYPE i.
    DATA content_as_table TYPE string_table.

    SPLIT content_as_json AT cl_abap_char_utilities=>newline INTO TABLE content_as_table.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        default_extension = `json` ##NO_TEXT
        default_file_name = substring_before( val = file_name sub = '.' occ = -1 )
      CHANGING
        filename          = user_input_filename
        path              = file_path
        fullpath          = fullpath
        user_action       = user_action
      EXCEPTIONS
        OTHERS            = 1 ) ##SUBRC_OK.

    IF sy-subrc <> 0.
      MESSAGE 'Error when exporting file'(031) TYPE 'E'.
      RETURN.
    ENDIF.
*     on mac computers file_save_dialog( ) does not add ".json" at the file_name ending.
    IF user_input_filename NP '*.json'.
      user_input_filename = |{ user_input_filename }.json| ##NO_TEXT.
      fullpath = |{ fullpath }.json| ##NO_TEXT.
    ENDIF.

    cl_gui_frontend_services=>gui_download(
      EXPORTING
        filename = user_input_filename
        write_lf = 'X'
      CHANGING
        data_tab = content_as_table
      EXCEPTIONS
        OTHERS   = 1 ) ##SUBRC_OK.
    IF sy-subrc <> 0.
      MESSAGE 'Error when exporting file'(031) TYPE 'E'.
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD handle_double_click_in_100.
    CLEAR selected_row.
    APPEND e_row TO selected_row.
    CALL SCREEN 200.
  ENDMETHOD.

  METHOD handle_double_click_in_200.
    APPEND e_row TO selected_row_api.
    CALL SCREEN 500.
  ENDMETHOD.

  METHOD user_command_in_scsr_overview.
    DATA: answer        TYPE char01,
          sel_row_index TYPE lvc_t_row.

    CASE scsr_ucomm.
      WHEN 'BACK'.
        CLEAR selected_row_api.
        alv_grid->set_selected_rows( it_index_rows = selected_row_api ).
        CALL SCREEN 200.

      WHEN 'RELOAD'.
        CALL SCREEN 500.
    ENDCASE.
  ENDMETHOD.


ENDCLASS.

START-OF-SELECTION.
  DATA(classification_manager) = NEW classification_manager( ).

  CALL SCREEN 100.

MODULE pbo_screen_100 OUTPUT.
  SET PF-STATUS 'STATUS_100'.
  SET TITLEBAR 'TITLE_100'.
  classification_manager->display_main_alv( ).
ENDMODULE.

MODULE pbo_screen_200 OUTPUT.
  SET TITLEBAR 'TITLE_200'.
  LOOP AT selected_row ASSIGNING FIELD-SYMBOL(<sel_row_title>).
    selected_file = data_files[ <sel_row_title>-index ].
    selected_file = data_files_full_names[ file_id = selected_file-file_id ].
    SELECT SINGLE data_type, source FROM zknsf_api_header INTO @DATA(api_db) WHERE file_id = @selected_file-file_id.
    IF api_db-data_type <> zknsf_cl_cache_write_api=>co_data_type_custom.
      DATA(hidden_buttons) = VALUE syucomm_t(
                                              ( 'DELETE' )
                                              ( 'EXPORT' ) ).
      SET PF-STATUS 'STATUS_200' EXCLUDING hidden_buttons.
    ELSE.
      SET PF-STATUS 'STATUS_200'.
    ENDIF.
  ENDLOOP.
  classification_manager->display_detail_alv( ).
ENDMODULE.

MODULE pbo_screen_500 OUTPUT.
  SET PF-STATUS 'STATUS_500'.
  classification_manager->display_successor_alv( ).
  SET TITLEBAR 'TITLE_500'.
ENDMODULE.

MODULE user_command_100 INPUT.
  classification_manager->user_command_in_file_overview( sy-ucomm ).
ENDMODULE.

MODULE user_command_200 INPUT.
  classification_manager->user_command_in_api_overview( sy-ucomm ).
ENDMODULE.

MODULE user_command_500 INPUT.
  classification_manager->user_command_in_scsr_overview( sy-ucomm ).
ENDMODULE.

MODULE force_exit INPUT.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.
