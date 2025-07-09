class ZKNSF_CL_USAGE_PREPROCESSOR definition
  public
  inheriting from CL_YCM_CC_USAGE_PREPROCESSOR
  create public .

public section.

  methods IF_YCM_CC_USAGE_PREPROCESSOR~GET_OBJECT_INFOS
    redefinition .
protected section.

  methods IS_KEY_USER_GENERATED
    importing
      !OBJECT_NAME type SOBJ_NAME
      !OBJECT_TYPE type TROBJTYPE
    returning
      value(IS_KEY_USER_GENERATED) type ABAP_BOOLEAN .

  methods PREPARE_USAGES
    redefinition .
private section.
ENDCLASS.



CLASS ZKNSF_CL_USAGE_PREPROCESSOR IMPLEMENTATION.


  METHOD prepare_usages.
    LOOP AT usages INTO DATA(usage) WHERE object_type = 'BADI_DEF'.
      " We also want BADI_DEF in our result and the super->prepare_usages would change the object_type to ENHS
      INSERT usage INTO TABLE result.
    ENDLOOP.

    " Get rid of the BADI_DEF for the super call, to avoid duplicate ENHS entries
    DATA(standard_usages) = usages.
    DELETE standard_usages WHERE object_type = 'BADI_DEF'.

    " Get the standard prepare_usages in
    DATA(parent) = super->prepare_usages( usages = standard_usages ).

    "Merge both
    LOOP AT parent INTO DATA(line).
      INSERT line INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_ycm_cc_usage_preprocessor~get_object_infos.
    CLEAR result.

    IF is_key_user_generated( object_type = object_type object_name = object_name ) IS NOT INITIAL.
      RETURN.
    ENDIF.

    RETURN super->if_ycm_cc_usage_preprocessor~get_object_infos(
        usages                  = usages
        is_filtering_dlvunit    = is_filtering_dlvunit
        object_type             = object_type
        object_name             = object_name
        is_filtering_namespaces = abap_true
        allowed_namespaces      = allowed_namespaces
    ).
  ENDMETHOD.


  METHOD is_key_user_generated.
    TRY.
        IF object_type = 'VIEW' AND get_nametab_infos_ddls( object_name ) = 'J'.
          " Check Text
          DATA p_dd25v_wa TYPE dd25v.
          DATA view_name TYPE ddobjname.
          view_name = object_name.
          CALL FUNCTION 'RS_ABAP_GET_DDIF_VIEW_E' DESTINATION rfc_dest
            EXPORTING
              p_name                = view_name
              p_state               = 'A'
              p_langu               = 'E'
            IMPORTING
              p_dd25v_wa            = p_dd25v_wa
            EXCEPTIONS
              illegal_input         = 1
              no_authorization      = 2
              communication_failure = 3
              system_failure        = 4
              OTHERS                = 5.
          IF sy-subrc <> 0.
            RETURN abap_false.
          ENDIF.
          IF p_dd25v_wa-ddtext CP '*Created from DDL source*'.
            RETURN abap_true.
          ENDIF.
        ENDIF.
      CATCH cx_ycm_cc_rfc_error.
        RETURN abap_false.
    ENDTRY.

    RETURN abap_false.
  ENDMETHOD.
ENDCLASS.
