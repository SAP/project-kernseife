class ltc_ycm_classic_api_compat definition final for testing duration short risk level harmless.

  private section.
    data: cut type ref to if_aff_compatibility_handler.
    methods:
      setup,
      get_supported_format_versions for testing,
      upgrade_v1_to_v2              for testing.

endclass.

class ltc_ycm_classic_api_compat implementation.

  method setup.
    cut = new cl_ycm_cc_classic_api_compat( ).
  endmethod.

  method get_supported_format_versions.
    data: act_result type if_aff_compatibility_handler=>ty_formats,
          exp_result type if_aff_compatibility_handler=>ty_formats.

    act_result = cut->get_supported_format_versions( ).

    exp_result = value #( ( format_version = '1' st_name = 'SYCM_XSLT_CLASSIC_API_LIST'    aff_type = 'IF_YCM_CLASSIC_API_LIST=>TY_MAIN' )
                          ( format_version = '2' st_name = 'SYCM_XSLT_CLASSIC_API_LIST_V2' aff_type = 'IF_YCM_CLASSIC_API_LIST_V2=>TY_MAIN' ) ).

    cl_abap_unit_assert=>assert_equals( act = act_result exp = exp_result ).
  endmethod.

  method upgrade_v1_to_v2.
    data: input_v1 type if_ycm_classic_api_list=>ty_main,
          act      type if_ycm_classic_api_list_v2=>ty_main.

    input_v1 = value #( format_version = '1' object_classifications = value #( ( state = if_ycm_classic_api_list=>co_state-classic_api ) ) ).

    cut->upgrade( exporting from   = '1'
                            to     = '2'
                            input  = input_v1
                  importing output = act ).

    cl_abap_unit_assert=>assert_equals( act = act-format_version exp = '2' ).
    cl_abap_unit_assert=>assert_equals( act = lines( act-object_classifications ) exp = 1 ).
    loop at act-object_classifications assigning field-symbol(<object>).
      cl_abap_unit_assert=>assert_equals( act = <object>-state exp = if_ycm_classic_api_list_v2=>co_state-classic_api ).
      cl_abap_unit_assert=>assert_table_contains( table = <object>-labels line = if_ycm_classic_api_list_v2=>co_labels-transactional_consistent ).
    endloop.
  endmethod.

endclass.
