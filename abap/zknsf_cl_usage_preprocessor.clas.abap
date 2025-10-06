class ZKNSF_CL_USAGE_PREPROCESSOR definition
  public
  inheriting from CL_YCM_CC_USAGE_PREPROCESSOR
  create public

  global friends ZKNSF_CL_API_USAGE .

public section.

  methods CONSTRUCTOR
    importing
      !RFC_DEST type RFC_DEST optional
    raising
      CX_YCM_CC_RFC_ERROR .

  methods IF_YCM_CC_USAGE_PREPROCESSOR~GET_OBJECT_INFOS
    redefinition .
  PROTECTED SECTION.

    METHODS is_key_user_generated
      IMPORTING
        !object_name                 TYPE sobj_name
        !object_type                 TYPE trobjtype
      RETURNING
        VALUE(is_key_user_generated) TYPE abap_boolean .

    METHODS is_cds_generated
      IMPORTING
        !object_name            TYPE sobj_name
        !object_type            TYPE trobjtype
      RETURNING
        VALUE(is_cds_generated) TYPE abap_boolean .

    METHODS prepare_usages
        REDEFINITION .

    TYPES: BEGIN OF ty_key_user_objects,
             object_type TYPE trobjtype,
             object_name TYPE trobj_name,
           END OF ty_key_user_objects.

    DATA key_user_objects TYPE HASHED TABLE OF ty_key_user_objects WITH UNIQUE KEY object_type object_name.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZKNSF_CL_USAGE_PREPROCESSOR IMPLEMENTATION.


  METHOD constructor.
    super->constructor( rfc_dest = rfc_dest ).

    " Load all Key-User Object
    SELECT FROM atov_u_item_bom_del FIELDS bom_object, bom_object_name  WHERE is_deleted = @abap_false INTO TABLE @key_user_objects.
  ENDMETHOD.


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

    IF is_cds_generated( object_type = object_type object_name = object_name ) IS NOT INITIAL.
      RETURN.
    ENDIF.


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


  METHOD is_cds_generated.
    CLEAR is_cds_generated.
    IF object_type = 'VIEW'.
      SELECT SINGLE FROM all_cds_sql_views FIELDS @abap_true WHERE sqlviewname = @object_name INTO @is_cds_generated.
    ENDIF.
  ENDMETHOD.


  METHOD is_key_user_generated.
    " Check if it is used in Custom Fields
    DATA object_name_30 TYPE c LENGTH 30.
    object_name_30 = object_name.
    SELECT SINGLE FROM cfd_w_rep_enh FIELDS @abap_true WHERE enhancement_object_name = @object_name_30  INTO @DATA(is_custom_field_stuff).
    IF sy-subrc EQ 0.
      RETURN abap_true.
    ENDIF.

    DATA(object_name_check) = object_name.
    DATA(object_type_check) = object_type.

    " For DB Views we need to check to corresponding DDLS, as Key-User generated objects unfortunatly don't use view entities (yet)
    IF object_type = 'VIEW'.
      " Find DDLS for this DB view
      SELECT SINGLE FROM all_cds_sql_views FIELDS ddlsourcename WHERE sqlviewname = @object_name INTO @DATA(cds_view_name).
      IF sy-subrc EQ 0.
        object_name_check = cds_view_name.
        object_type_check = 'DDLS'.
      ENDIF.
    ENDIF.

    IF line_exists( key_user_objects[ object_type = object_type_check object_name = object_name_check ] ).
      RETURN abap_true.
    ENDIF.

    " Check if it is a Custom Business Object CDS View
    DATA object_name_16 TYPE c LENGTH 16.
    object_name_16 = object_name.
    SELECT SINGLE FROM scbo_node FIELDS @abap_true WHERE cds_view_name = @object_name_30 OR abap_view_name = @object_name_16 INTO @DATA(is_cbo).
    IF sy-subrc EQ 0.
      RETURN abap_true.
    ENDIF.

    RETURN abap_false.
  ENDMETHOD.
ENDCLASS.
