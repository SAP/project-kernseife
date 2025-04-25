class ZKNSF_CL_CLASSIFICATION_MANGR definition
  public
  inheriting from CL_YCM_CC_CLASSIFICATION_MANGR
  create public .

public section.

  types:
    BEGIN OF ENUM custom_file_type STRUCTURE ty_custom_file_type,
        kernseife_custom,
        kernseife_legacy,
      END OF ENUM  custom_file_type STRUCTURE ty_custom_file_type .

  methods CONSTRUCTOR
    importing
      !FILE_DOWNLOADER type ref to IF_YCM_CC_FILE_DOWNLOADER optional .
  methods UPLOAD_CUSTOM_FILE
    importing
      !FILE_TYPE type CUSTOM_FILE_TYPE
      !FILE_NAME type STRING
      !FILE_CONTENT type STRING_TABLE
      !UPLOADER type UNAME optional
    raising
      CX_YCM_CC_PROVIDER_ERROR .

  methods DELETE_ALL
    redefinition .
  methods DELETE_FILE
    redefinition .
  methods GET_DATA
    redefinition .
protected section.
private section.

  data FILE_DOWNLOADER type ref to IF_YCM_CC_FILE_DOWNLOADER .
  data CACHE_WRITER type ref to ZKNSF_CL_CACHE_WRITE_API .

  methods UPLOAD_XSTRING
    importing
      !URL type STRING
      !FILE_TYPE type CUSTOM_FILE_TYPE
      !CONTENT type XSTRING
      !SOURCE type STRING
      !COMMIT_HASH type STRING optional
      !LAST_GIT_CHECK type TIMESTAMP optional
      !UPLOADER type UNAME optional
    raising
      CX_YCM_CC_PROVIDER_ERROR .
ENDCLASS.



CLASS ZKNSF_CL_CLASSIFICATION_MANGR IMPLEMENTATION.


  METHOD constructor.
    super->constructor( file_downloader = file_downloader ).
    me->file_downloader = COND #( WHEN file_downloader IS SUPPLIED THEN file_downloader
                                       ELSE NEW cl_ycm_cc_file_downloader( ) ).

    cache_writer = NEW zknsf_cl_cache_write_api( ).
  ENDMETHOD.


  method UPLOAD_CUSTOM_FILE.
        DATA(content) = concat_lines_of( file_content ).
    DATA(content_xstring) = cl_abap_codepage=>convert_to( content ).

    upload_xstring( content   = content_xstring
                    url       = file_name
                    file_type = file_type
                    source    = source_local
                    uploader  = uploader ).
  endmethod.


  METHOD upload_xstring.
    DATA: compatibility_handler TYPE REF TO if_aff_compatibility_handler,
          content_handler       TYPE REF TO if_aff_content_handler.

    TRY.
        IF file_type = ty_custom_file_type-kernseife_custom.
          compatibility_handler = NEW zknsf_cl_json_compat( ).
          content_handler = cl_aff_content_handler_factory=>get_handler_for_json_compat( compatibility_handler ).

          DATA kernseife_content TYPE zknsf_if_api_v1=>ty_main.

          TRY.
              content_handler->deserialize( EXPORTING content = content
                                            IMPORTING data    = kernseife_content ).
            CATCH cx_aff_root.
              RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '106' ).
          ENDTRY.

          IF lines( kernseife_content-object_classifications ) > 0 AND lines( kernseife_content-ratings ) > 0.
            cache_writer->write_custom(
              imported_objects = kernseife_content
              url              = url
              commit_hash      = commit_hash
              source           = source
              last_git_check   = last_git_check
              uploader         = uploader ).
          ELSE.
            RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '105' ).
          ENDIF.

        ENDIF.
      CATCH cx_aff_root INTO DATA(exception).
        RAISE EXCEPTION NEW cx_ycm_cc_provider_error( previous = exception ).
      CATCH cx_uuid_error.
        RAISE EXCEPTION NEW cx_ycm_cc_provider_error( ).
    ENDTRY.
  ENDMETHOD.


  METHOD delete_all.
    AUTHORITY-CHECK OBJECT 'SYCM_API'
              ID 'ACTVT'     FIELD '06'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '109' ).
    ENDIF.

    DELETE FROM zknsf_api_cache.                        "#EC CI_NOWHERE
    DELETE FROM zknsf_api_header.                       "#EC CI_NOWHERE
    DELETE FROM zknsf_api_label.                        "#EC CI_NOWHERE
    DELETE FROM zknsf_api_scsr.                         "#EC CI_NOWHERE

    DELETE FROM zknsf_ratings.                          "#EC CI_NOWHERE
  ENDMETHOD.


  METHOD delete_file.
    SELECT SINGLE file_id FROM zknsf_api_header WHERE url = @url INTO @DATA(file_id) ##WARN_OK. "#EC CI_NOORDER

    DELETE FROM zknsf_api_label WHERE api_id IN ( SELECT api_id FROM zknsf_api_cache WHERE file_id = @file_id ).
    DELETE FROM zknsf_api_scsr WHERE api_id IN ( SELECT api_id FROM zknsf_api_cache WHERE file_id = @file_id ).
    DELETE FROM zknsf_api_cache WHERE file_id = @file_id.
    DELETE FROM zknsf_api_header WHERE file_id = @file_id.

    DELETE FROM zknsf_ratings.                          "#EC CI_NOWHERE
  ENDMETHOD.


  method GET_DATA.
 data: data_file   type api_type.

    authority-check object 'SYCM_API'
              id 'ACTVT'     field '03'.
    if sy-subrc <> 0.
      raise exception new cx_ycm_cc_provider_error( msgno = '108' ).
    endif.

    select * from zknsf_api_header into table @data(db_files). "#EC CI_NOWHERE

    loop at db_files assigning field-symbol(<file>).
      move-corresponding <file> to data_file.

      data_file-created = |{ <file>-created timestamp = environment }|.

      if data_file-last_git_check <> 0.

        data_file-last_git_check = |{ <file>-last_git_check timestamp = environment }|.

      endif.

      if <file>-data_type = ZKNSF_CL_CACHE_WRITE_API=>CO_DATA_TYPE_CUSTOM.
        data_file-data_type = 'Kernseife'(001).
      endif.

      append data_file to result.
    endloop.
  endmethod.
ENDCLASS.
