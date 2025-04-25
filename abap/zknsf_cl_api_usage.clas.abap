class ZKNSF_CL_API_USAGE definition
  public
  inheriting from CL_YCM_CC_CHECK_API_USAGE
  final
  create public .

public section.

  constants:
    BEGIN OF custom_message_codes,
        no_class TYPE sci_errc VALUE 'NOC',
        missing  TYPE sci_errc VALUE 'MISSING',
      END OF custom_message_codes .

  methods CONSTRUCTOR .
protected section.

  data:
    ratings TYPE SORTED TABLE OF zknsf_i_ratings WITH NON-UNIQUE  KEY primary_key COMPONENTS code .

  methods GET_MESSAGE_CODES
    importing
      !MYNAME type SCI_CHK optional
    returning
      value(RESULT) type SCIMESSAGES .

  methods EVALUATE_MESSAGE_CODE
    redefinition .
  methods GET_ALLOWED_USAGE_OBJECT_TYPES
    redefinition .
  methods COLLECT_ALL_SUCCESSORS
    redefinition .
private section.

  class-data ATTRIBUTE_UTILS type ref to IF_YCM_CC_ATTRIBUTE_UTILS .
  class-data CHECKED_SYS_RELEASE_PROVIDER type ref to IF_YCM_CC_PROVIDER_RELEASE_API .
  class-data RELEASE_PROVIDER type ref to IF_YCM_CC_PROVIDER_RELEASE_API .
  class-data CLASSIC_PROVIDER type ref to IF_YCM_CC_PROVIDER_CLASSIC_API .
  class-data USAGE_PREPROCESSOR type ref to IF_YCM_CC_USAGE_PREPROCESSOR .
  class-data NON_SOURCE_PROCESSOR type ref to IF_YCM_CC_NON_SOURCE_PROCESSOR .
  data RELEASE_SOURCE_ATTR type SYCM_ATTR_RELEASE_SOURCE .
  data CLASSIC_SOURCE_ATTR type SYCM_ATTR_CLASSIC_SOURCE .
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

    INSERT LINES OF get_message_codes( myname = myname ) INTO TABLE scimessages.

    " default values for check attributes
    release_source_attr = classification_source-checked_system.
    classic_source_attr = 'ZKNSF_CL_PROVIDER_WITH_CACHE' ##NO_TEXT.
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
      INSERT VALUE scimessage( test = myname
                               code = rating-code
                               kind = rating-criticality
                               text = rating-title ) INTO TABLE result.

      INSERT VALUE scimessage( test = myname
                               code = |{ rating-code }_SUC|
                               kind = rating-criticality
                               text = |{ rating-title } ' (successor available)'| ) INTO TABLE result.
    ENDLOOP.

    " Try to insert again, in case it doesn't exist
    INSERT VALUE scimessage( test = myname
                             code = custom_message_codes-no_class
                             kind = error
                             text = 'Missing Classification'(001) ) INTO TABLE result.

    INSERT VALUE scimessage( test = myname
                             code = custom_message_codes-missing
                             kind = error
                             text = 'Missing Rating'(002) ) INTO TABLE result.
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

      "TODO Define if this makes sense
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
ENDCLASS.
