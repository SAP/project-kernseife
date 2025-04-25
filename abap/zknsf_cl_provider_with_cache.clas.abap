class ZKNSF_CL_PROVIDER_WITH_CACHE definition
  public
  final
  create public .

public section.

  interfaces IF_YCM_CC_PROVIDER_CLASSIC_API .

  methods CONSTRUCTOR
    raising
      CX_YCM_CC_PROVIDER_ERROR .
  PROTECTED SECTION.
private section.
ENDCLASS.



CLASS ZKNSF_CL_PROVIDER_WITH_CACHE IMPLEMENTATION.


  METHOD constructor.


  ENDMETHOD.


  METHOD if_ycm_cc_provider_classic_api~get_classifications.
    IF lines( apis ) = 0.
      RETURN.
    ENDIF.

    SELECT * FROM zknsf_apis_c_scsr FOR ALL ENTRIES IN @apis WHERE  tadir_object   = @apis-trobjtype
                                                              AND   tadir_obj_name = @apis-sobj_name
                                                              AND   object_type    = @apis-object_type
                                                              AND   object_key     = @apis-sub_key INTO TABLE @DATA(api_with_successor_info).

    LOOP AT api_with_successor_info ASSIGNING FIELD-SYMBOL(<classic_api_bundle>) GROUP BY ( tadir_object   = <classic_api_bundle>-tadir_object
                                                                                            tadir_obj_name = <classic_api_bundle>-tadir_obj_name
                                                                                            object_type    = <classic_api_bundle>-object_type
                                                                                            object_key     = <classic_api_bundle>-object_key ) .

      DATA successors TYPE if_ycm_classic_api_list_v2=>ty_object_classification-successors.
      DATA labels TYPE if_ycm_classic_api_list_v2=>tt_labels.

      CLEAR successors.
      CLEAR labels.

      LOOP AT GROUP <classic_api_bundle> ASSIGNING FIELD-SYMBOL(<classic_api>).

        IF <classic_api>-successor_tadir_object IS NOT INITIAL.
          IF NOT line_exists( successors[ tadir_object   = <classic_api>-successor_tadir_object
                                          tadir_obj_name = <classic_api>-successor_tadir_obj_name
                                          object_type    = <classic_api>-successor_object_type
                                          object_key     = <classic_api>-successor_object_key ] ).

            INSERT VALUE #( tadir_object   = <classic_api>-successor_tadir_object
                            tadir_obj_name = <classic_api>-successor_tadir_obj_name
                            object_type    = <classic_api>-successor_object_type
                            object_key     = <classic_api>-successor_object_key ) INTO TABLE successors.
          ENDIF.
        ENDIF.

        IF <classic_api>-label_name IS NOT INITIAL.
          IF NOT line_exists( labels[ table_line = <classic_api>-label_name ] ).
            INSERT CONV #( <classic_api>-label_name ) INTO TABLE labels.
          ENDIF.
        ENDIF.

      ENDLOOP.

      INSERT VALUE #( tadir_object          = <classic_api_bundle>-tadir_object
                      tadir_obj_name        = <classic_api_bundle>-tadir_obj_name
                      object_type           = <classic_api_bundle>-object_type
                      object_key            = <classic_api_bundle>-object_key
                      software_component    = <classic_api_bundle>-software_component
                      application_component = <classic_api_bundle>-application_component
                      state                 = <classic_api_bundle>-state
                      successors            = successors
                      labels                = labels ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
