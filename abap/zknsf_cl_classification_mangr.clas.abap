CLASS zknsf_cl_classification_mangr DEFINITION
  PUBLIC
  INHERITING FROM cl_ycm_cc_classification_mangr
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ENUM custom_file_type STRUCTURE ty_custom_file_type,
        kernseife_custom,
        kernseife_legacy,
      END OF ENUM  custom_file_type STRUCTURE ty_custom_file_type .

    METHODS constructor
      IMPORTING
        !file_downloader TYPE REF TO if_ycm_cc_file_downloader OPTIONAL .
    METHODS upload_custom_file
      IMPORTING
        !file_type    TYPE custom_file_type
        !file_name    TYPE string
        !file_content TYPE string_table
        !uploader     TYPE syuname OPTIONAL
      RAISING
        cx_ycm_cc_provider_error .
    METHODS get_custom_api_file_as_json
      IMPORTING
        !file_id      TYPE guid
      RETURNING
        VALUE(result) TYPE string
      RAISING
        cx_ycm_cc_provider_error .

    METHODS delete_all
        REDEFINITION .
    METHODS delete_file
        REDEFINITION .
    METHODS get_api_files
        REDEFINITION .
    METHODS get_data
        REDEFINITION .
    METHODS get_apis
        REDEFINITION .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA file_downloader TYPE REF TO if_ycm_cc_file_downloader .
    DATA cache_writer TYPE REF TO zknsf_cl_cache_write_api .

    METHODS upload_xstring
      IMPORTING
        !url            TYPE string
        !file_type      TYPE custom_file_type
        !content        TYPE xstring
        !source         TYPE string
        !commit_hash    TYPE string OPTIONAL
        !last_git_check TYPE timestamp OPTIONAL
        !uploader       TYPE syuname OPTIONAL
      RAISING
        cx_ycm_cc_provider_error .
ENDCLASS.



CLASS ZKNSF_CL_CLASSIFICATION_MANGR IMPLEMENTATION.


  METHOD constructor.
    super->constructor( file_downloader = file_downloader ).
    me->file_downloader = COND #( WHEN file_downloader IS SUPPLIED THEN file_downloader
                                       ELSE NEW cl_ycm_cc_file_downloader( ) ).

    cache_writer = NEW zknsf_cl_cache_write_api( ).
  ENDMETHOD.


  METHOD upload_custom_file.
    DATA(content) = concat_lines_of( file_content ).
    DATA(content_xstring) = cl_abap_codepage=>convert_to( content ).

    upload_xstring( content   = content_xstring
                    url       = file_name
                    file_type = file_type
                    source    = source_local
                    uploader  = uploader ).
  ENDMETHOD.


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
    AUTHORITY-CHECK OBJECT 'SYCM_API' ID 'ACTVT' FIELD '06'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '109' ).
    ENDIF.

    cache_writer->delete_all( ).

  ENDMETHOD.


  METHOD delete_file.
    IF skip_authority_check = abap_false.
      AUTHORITY-CHECK OBJECT 'SYCM_API' ID 'ACTVT' FIELD '06'.

      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '109' ).
      ENDIF.
    ENDIF.

    cache_writer->delete_file( url = url ).
  ENDMETHOD.


  METHOD get_data.
    "# Deprecated
    result = get_api_files( ).
  ENDMETHOD.


  METHOD get_apis.
    AUTHORITY-CHECK OBJECT 'SYCM_API' ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '108' ).
    ENDIF.

    result = cache_writer->get_apis( file_id = file_id ).
  ENDMETHOD.


  METHOD get_api_files.
    AUTHORITY-CHECK OBJECT 'SYCM_API' ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '108' ).
    ENDIF.

    result = cache_writer->get_api_files( ).
  ENDMETHOD.


  METHOD get_custom_api_file_as_json.
    AUTHORITY-CHECK OBJECT 'SYCM_API' ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '108' ).
    ENDIF.

    DATA(classic_api_aff) = cache_writer->get_custom_apis_aff( file_id ).

    IF lines( classic_api_aff-object_classifications ) = 0.
      RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '118' ).
    ENDIF.

    DATA(compatibility_handler)  = NEW cl_ycm_cc_classic_api_compat( ).
    DATA(content_handler) = cl_aff_content_handler_factory=>get_handler_for_json_compat( compatibility_handler ).
    TRY.
        result = cl_abap_codepage=>convert_from( content_handler->serialize( classic_api_aff ) ).
      CATCH cx_aff_root INTO DATA(serialization_error).
        RAISE EXCEPTION NEW cx_ycm_cc_provider_error( previous = serialization_error ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
