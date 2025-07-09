class ZKNSF_CL_API_USAGE definition
  public
  inheriting from CL_YCM_CC_CHECK_API_USAGE
  final
  create public .

public section.

  constants:
    BEGIN OF custom_message_codes,
        no_class                    TYPE sci_errc VALUE 'NOC',
        missing                     TYPE sci_errc VALUE 'MISSING',
        db_tables_generic           TYPE sci_errc VALUE 'TBL',
        db_tables_select            TYPE sci_errc VALUE 'TBLSEL',
        db_tables_select_successor  TYPE sci_errc VALUE 'TBLSEL_SUC',
        db_tables_update            TYPE sci_errc VALUE 'TBLUPD',
        db_tables_update_successor  TYPE sci_errc VALUE 'TBLUPD_SUC',
        db_tables_in_cds            TYPE sci_errc VALUE 'TBLCDS',
        db_tables_in_cds_successor  TYPE sci_errc VALUE 'TBLCDS_SUC',
        db_tables_as_type           TYPE sci_errc VALUE 'TBLTYP',
        db_tables_as_type_successor TYPE sci_errc VALUE 'TBLTYP_SUC',
      END OF custom_message_codes .

  methods CONSTRUCTOR .

  methods GET_ATTRIBUTES
    redefinition .
  methods IF_CI_TEST~QUERY_ATTRIBUTES
    redefinition .
  methods PUT_ATTRIBUTES
    redefinition .
protected section.

  data:
    ratings TYPE SORTED TABLE OF zknsf_i_ratings WITH NON-UNIQUE  KEY primary_key COMPONENTS code .

  methods GET_MESSAGE_CODES
    returning
      value(RESULT) type SCIMESSAGES .
  methods INFORM_LANGUAGE_VERSION
    importing
      !LANGUAGE_VERSION type IF_ABAP_LANGUAGE_VERSION=>TY_VERSION .
  methods GET_MESSAGE_CODE
    importing
      !CODE type ZKNSF_RATING_CODE
      !TITLE type ZKNSF_RATING_TITLE
      !SUCCESSOR type ABAP_BOOLEAN
      !KIND type SYCHAR01 default 'E'
    returning
      value(RESULT) type SCIMESSAGE .

  methods COLLECT_ALL_SUCCESSORS
    redefinition .
  methods EVALUATE_MESSAGE_CODE
    redefinition .
  methods EVALUATE_TABL_MESSAGE_CODE
    redefinition .
  methods GET_ALLOWED_USAGE_OBJECT_TYPES
    redefinition .
  methods GET_OBJECT_LANGUAGE_VERSION
    redefinition .
  methods GET_USAGE_PREPROCESSOR
    redefinition .
  methods INFORM_ATC
    redefinition .
private section.

  data:
    sw_component_list TYPE SORTED TABLE OF dlvunit WITH UNIQUE DEFAULT KEY .
  data TRACK_LANGUAGE_VERSION_ATTR type ABAP_BOOLEAN .
ENDCLASS.



CLASS ZKNSF_CL_API_USAGE IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).

    description         = 'Kernseife: Usage of APIs'(000).
    version             = '000'.
    category            = 'ZKNSF_CL_CI_CATEGORY' ##NO_TEXT.
    has_attributes      = abap_true.
    has_documentation   = abap_false.
    remote_enabled      = abap_true.
    remote_rfc_enabled  = abap_true.
    uses_checksum       = abap_true.
    check_scope_enabled = abap_true.

    INSERT LINES OF get_message_codes( ) INTO TABLE scimessages.


    track_language_version_attr = abap_false.

    SELECT DISTINCT software_component FROM zknsf_api_cache INTO TABLE @sw_component_list. "#EC CI_BYPASS "#EC CI_GENBUFF "#EC CI_NOWHERE


    classic_source_attr = 'ZKNSF_CL_PROVIDER_WITH_CACHE' ##NO_TEXT.
    release_source_attr = classification_source-checked_system.
  ENDMETHOD.


  METHOD get_message_codes.
    CONSTANTS:
      error   TYPE sychar01 VALUE cl_ycm_cc_check_api_usage=>c_error,
      warning TYPE sychar01 VALUE cl_ycm_cc_check_api_usage=>c_warning,
      info    TYPE sychar01 VALUE cl_ycm_cc_check_api_usage=>c_info.


    IF ratings IS INITIAL.
      SELECT code, title, criticality FROM zknsf_i_ratings INTO TABLE @ratings ORDER BY code.
    ENDIF.

    LOOP AT ratings INTO DATA(rating).
      " Add Code with and without Successor
      INSERT get_message_code(  code = rating-code kind = rating-criticality title = rating-title successor = abap_false ) INTO TABLE result.
      INSERT get_message_code(  code = rating-code kind = rating-criticality title = rating-title successor = abap_true ) INTO TABLE result.
    ENDLOOP.

    " Table Usage special Messages
    INSERT get_message_code(  code = custom_message_codes-db_tables_select title = 'Reading from SAP database tables or table views'(016) kind = warning successor = abap_false ) INTO TABLE result.
    INSERT get_message_code(  code = custom_message_codes-db_tables_select title = 'Reading from SAP database tables or table views'(016) kind = error   successor = abap_true  ) INTO TABLE result.

    INSERT get_message_code(  code = custom_message_codes-db_tables_update title = 'Updating SAP database tables or table views'(017) kind = error successor = abap_false ) INTO TABLE result.
    INSERT get_message_code(  code = custom_message_codes-db_tables_update title = 'Updating SAP database tables or table views'(017) kind = error successor = abap_true  ) INTO TABLE result.

    INSERT get_message_code(  code = custom_message_codes-db_tables_in_cds title = 'Usage of SAP database tables in CDS views'(018) kind = warning successor = abap_false ) INTO TABLE result.
    INSERT get_message_code(  code = custom_message_codes-db_tables_in_cds title = 'Usage of SAP database tables in CDS views'(018) kind = error   successor = abap_true  ) INTO TABLE result.

    INSERT get_message_code(  code = custom_message_codes-db_tables_as_type title = 'Usage of SAP database tables as type definition'(019) kind = info successor = abap_false ) INTO TABLE result.
    INSERT get_message_code(  code = custom_message_codes-db_tables_as_type title = 'Usage of SAP database tables as type definition'(019) kind = info   successor = abap_true  ) INTO TABLE result.

    " Error Message Codes
    INSERT get_message_code(  code = custom_message_codes-no_class title =  'Missing Classification'(001) successor = abap_false ) INTO TABLE result.
    INSERT get_message_code(  code = custom_message_codes-missing  title =  'Missing Rating'(002) successor = abap_false ) INTO TABLE result.


    " Language Version Message Codes
    INSERT get_message_code( code = CONV zknsf_rating_code( if_abap_language_version=>gc_version-standard )           title = 'Standard ABAP'(010)               successor = abap_false ) INTO TABLE result.
    INSERT get_message_code( code = CONV zknsf_rating_code( if_abap_language_version=>gc_version-key_user )           title = 'ABAP for Key Users'(011)          successor = abap_false ) INTO TABLE result.
    INSERT get_message_code( code = CONV zknsf_rating_code( if_abap_language_version=>gc_version-sap_cloud_platform ) title = 'ABAP for Cloud Development'(012)  successor = abap_false ) INTO TABLE result.


  ENDMETHOD.


  METHOD get_allowed_usage_object_types.
    RETURN VALUE #( sign = 'I' option = 'EQ' ( low = 'INTF' )
                                             ( low = 'CLAS' )
                                             ( low = 'FUNC' )
                                             ( low = 'DDLS' )
                                             ( low = 'TABL' )
                                             ( low = 'VIEW' )
                                             ( low = 'PROG' )
                                             ( low = 'BDEF' )
                                             ( low = 'TRAN' )
                                             ( low = 'AUTH' )
                                             ( low = 'SUSO' )
                                             ( low = 'MSAG' )
                                             ( low = 'ACID' )
                                             ( low = 'PARA' )
                                             ( low = 'XSLT' )
                                             ( low = 'TYPE' )
                                             ( low = 'SHLP' )
                                             ( low = 'DTEL' )
                                             ( low = 'DOMA' )
                                             ( low = 'TTYP' )
                                             ( low = 'SMTG' )
                                             ( low = 'DRTY' )
                                             ( low = 'DSFI' )
                                             ( low = 'DSFD' )
                                             ( low = 'RONT' )
                                             ( low = 'NONT' )
                                             ( low = 'ENHS' )
                                             ( low = 'ENHO' )
                                             ( low = 'SXSD' )
                  ).
  ENDMETHOD.


  METHOD evaluate_message_code.

    " First Check "Classic" meaning Kernseife
    IF classic_status IS NOT INITIAL.
      IF line_exists( ratings[ code = classic_status-state ] ).
        RETURN classic_status-state.
      ENDIF.
      RETURN custom_message_codes-missing.
    ENDIF.

    " check data from release info data provider
    IF release_status IS NOT INITIAL.
      IF release_status-state = if_aff_released_check_objs=>co_release_state-released.
        RETURN.
      ENDIF.

      IF release_status-state = if_aff_released_check_objs=>co_release_state-deprecated.
        RETURN message_codes-deprecated.
      ENDIF.
    ENDIF.

    RETURN custom_message_codes-no_class.

  ENDMETHOD.


  METHOD collect_all_successors.
    result = super->collect_all_successors(
      classic_status = classic_status
      release_status = release_status ).

    " As Kernseife also has the Released Objects, for those we have duplicate successor entries
    SORT result.
    DELETE ADJACENT DUPLICATES FROM result COMPARING ALL FIELDS.

  ENDMETHOD.


  METHOD get_attributes.
    EXPORT
        track_language_version = track_language_version_attr
    TO DATA BUFFER p_attributes.
  ENDMETHOD.


  METHOD get_object_language_version.
    TRY.
        p_version = super->get_object_language_version( ).

        IF track_language_version_attr IS NOT INITIAL.
          inform_language_version( language_version = p_version ).
        ENDIF.
        " Need to split the exception, otherwise the compiler can't handle the ambigious type
      CATCH cx_ci_no_release_info INTO DATA(no_release_info).
        p_version = if_abap_language_version=>gc_version-standard.
        IF track_language_version_attr IS NOT INITIAL.
          inform_language_version( language_version = p_version ).
        ENDIF.
        RAISE EXCEPTION no_release_info.
      CATCH cx_ci_object_version_not_found INTO DATA(object_version_not_found).
        p_version = if_abap_language_version=>gc_version-standard.
        IF track_language_version_attr IS NOT INITIAL.
          inform_language_version( language_version = p_version ).
        ENDIF.
        RAISE EXCEPTION object_version_not_found.
    ENDTRY.

  ENDMETHOD.


  METHOD if_ci_test~query_attributes.

    DATA(attributes) = VALUE sci_atttab( ( id   = 'trackLanguageVersion'
                                           text = 'Track Language Version'(057)
                                           ref  = REF #( track_language_version_attr )
                                           kind = cl_ci_query_attributes=>c_attribute_kinds-checkbox ) ) ##NO_TEXT ##NO_TEXT.

    DATA message TYPE c LENGTH 100.
    attributes_ok = abap_true. " as we don't check anything


    DATA(cancel) = cl_ci_query_attributes=>generic( p_name       = myname
                                                    p_title      = 'Usage of APIs'(000)
                                                    p_attributes = attributes
                                                    p_display    = p_display
                                                    p_message    = message ).

    IF cancel = abap_true OR p_display = abap_true.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD inform_atc.
    " Check if Object is not a Custom Object
    IF message_code = custom_message_codes-no_class AND NOT line_exists( sw_component_list[ table_line = used_api-dlvunit ] ).
      RETURN.
    ENDIF.

    " As this logic is implemented in a local class by standard, we can't reuse it...
    DATA(has_successor) = xsdbool( lines( successors ) > 0 ).
    DATA code_with_successor TYPE scimessage-code.
    code_with_successor = COND #( WHEN has_successor = abap_true THEN |{ message_code }_SUC| ELSE message_code ).

    DATA(available_message_codes) = get_message_codes( ).
    IF line_exists( available_message_codes[ code = code_with_successor ] ) ##WARN_OK.
      super->inform_atc(
        message_code = code_with_successor
        used_api     = used_api
        successors   = successors
      ).
    ELSE.
      super->inform_atc(
        message_code = message_code
        used_api     = used_api
        successors   = successors
      ).
    ENDIF.

  ENDMETHOD.


  METHOD inform_language_version.

    DATA code TYPE sci_errc.

    " Report Source Code the Same...
    IF language_version = if_abap_language_version=>gc_version-standard.
      code = if_abap_language_version=>gc_version-standard_source_code.
    ELSE.
      code = language_version.
    ENDIF.

    inform(
      p_code         = code
      p_test         = myname
      p_sub_obj_type = object_type
      p_sub_obj_name = object_name
      p_checksum_1   = -1 ).

  ENDMETHOD.


  METHOD put_attributes.

    IMPORT
       track_language_version = track_language_version_attr
     FROM DATA BUFFER p_attributes.
  ENDMETHOD.


  METHOD evaluate_tabl_message_code.
    DATA(code) = super->evaluate_tabl_message_code( used_api ).
    " Map Standard Code to TBL_ Code to support Scoring and also increase priority to 1 for objects with successors
    CASE code.
      WHEN  message_codes-db_tables_in_cds.
        RETURN custom_message_codes-db_tables_in_cds.
      WHEN  message_codes-select_database.
        RETURN custom_message_codes-db_tables_select.
      WHEN message_codes-update_database.
        RETURN custom_message_codes-db_tables_update.
      WHEN OTHERS.
        " This could mean this is used as a Type definition
        TRY.
            " Read Classification (as standard doesn't pass it into this method..
            DATA(usages) = VALUE if_ycm_cc_usage_preprocessor=>ty_usages( ( trobjtype = used_api-trobjtype sobj_name = used_api-sobj_name object_type = used_api-object_type sub_key = used_api-sub_key ) ).
            DATA(classic_provider) = NEW zknsf_cl_provider_with_cache( ).
            DATA(classic_info) = classic_provider->if_ycm_cc_provider_classic_api~get_classifications( usages ).
            DATA(classic_status) = VALUE #( classic_info[ object_type = used_api-object_type
                                                          object_key  = used_api-sub_key ] OPTIONAL ).

            IF classic_status IS NOT INITIAL.
              IF classic_status-state = custom_message_codes-db_tables_generic.
                RETURN custom_message_codes-db_tables_as_type.
              ELSE.
                " Structures => Just report the normal rating
                RETURN classic_status-state.
              ENDIF.
            ELSE.
              " No Classification
              RETURN custom_message_codes-no_class.
            ENDIF.
          CATCH cx_ycm_cc_provider_error.
            RETURN custom_message_codes-no_class.
        ENDTRY.
    ENDCASE.
  ENDMETHOD.


  METHOD get_message_code.
    result = VALUE scimessage( test = myname
                               code = COND #( WHEN successor = abap_true THEN |{ code }_SUC| ELSE code )
                               kind = kind
                               text = COND #( WHEN successor = abap_true THEN |{ title } (successor available)| ELSE title )
                             ).
  ENDMETHOD.


  METHOD get_usage_preprocessor.
    RETURN NEW zknsf_cl_usage_preprocessor( rfc_destination ).
  ENDMETHOD.
ENDCLASS.
