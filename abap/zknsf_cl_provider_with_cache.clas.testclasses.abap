class ltcl_data_provider_cache definition final for testing duration short risk level harmless.

  public section.
    interfaces:
      if_ycm_classic_api_list_v2,
      if_aff_released_check_objs.

  private section.
    aliases:
     tt_classic_api for if_ycm_classic_api_list_v2~ty_main,
     tt_release_api for if_aff_released_check_objs~ty_main.

    data:
      cut                type ref to cl_ycm_cc_provider_with_cache,
      manager_testdouble type ref to cl_ycm_cc_classification_mangr.

    class-data:
      environment       type ref to if_cds_test_environment.

    class-methods:
      class_setup,
      class_teardown.

    methods:
      setup                        raising cx_static_check,
      insert_mock_data_classic     raising cx_static_check,
      insert_mock_data_release     raising cx_static_check,
      r_api_returned               for testing raising cx_static_check,
      r_api_return_one_successor   for testing raising cx_static_check,
      r_api_return_mltpl_successor for testing raising cx_static_check,
      r_api_search_mltpl_apis      for testing raising cx_static_check,
      c_api_returned               for testing raising cx_static_check,
      c_api_return_one_successor   for testing raising cx_static_check,
      c_api_return_mltpl_successor for testing raising cx_static_check,
      c_api_search_mltpl_apis      for testing raising cx_static_check,
      swc_are_returned             for testing raising cx_static_check,
      classification_manager_call  for testing raising cx_static_check.

endclass.

class ltcl_data_provider_cache implementation.

  method setup.
    environment->clear_doubles( ).

    manager_testdouble ?= cl_abap_testdouble=>create( 'cl_ycm_cc_classification_mangr' ).

    cut = new #( classification_manager = manager_testdouble
                 url                    = 'github.com/file.json'
                 file_type              = cl_ycm_cc_classification_mangr=>ty_file_type-classic_file ).

    insert_mock_data_classic( ).
    insert_mock_data_release( ).
  endmethod.

  method class_setup.
    environment = cl_cds_test_environment=>create_for_multiple_cds( value #(
                        ( i_for_entity = 'sycm_apis_c_scsr' )
                        ( i_for_entity = 'sycm_apis_r_scsr' ) ) ).
  endmethod.

  method insert_mock_data_classic.
    data:
      td_classic_apis   type standard table of sycm_api_cache with empty key,
      td_classic_apis_h type standard table of sycm_api_header with empty key,
      td_classic_apis_s type standard table of sycm_api_scsr with empty key,
      td_classic_apis_l type standard table of sycm_api_label with empty key.

    " Prepare test data for 'sycm_api_cache'
    td_classic_apis = value #( (
                               file_Id               = '10'
                               api_id                = '20'
                               tadir_object          = 'CLAS'
                               tadir_obj_name        = '/BCV/CL_AUT_AUTHORIZATION'
                               object_type           = 'CLAS'
                               object_key            = '/BCV/CL_AUT_AUTHORIZATION'
                               software_component    = 'S4FND'
                               application_component = 'CA-EPT-BCV'
                               state                 = if_ycm_classic_api_list_v2=>co_state-classic_api
                               )
                               (
                               file_Id               = '10'
                               api_id                = '22'
                               tadir_object          = 'CLAS'
                               tadir_obj_name        = 'CF_REBD_BUILDING'
                               object_type           = 'CLAS'
                               object_key            = 'CF_REBD_BUILDING'
                               software_component    = 'S4CORE'
                               application_component = 'RE-FX-BD'
                               state                 = if_ycm_classic_api_list_v2=>co_state-no_api
                               )
                               (
                               file_Id               = '10'
                               api_id                = '23'
                               tadir_object          = 'CLAS'
                               tadir_obj_name        = 'CF_REBD_BUSINESS_ENTITY'
                               object_type           = 'CLAS'
                               object_key            = 'CF_REBD_BUSINESS_ENTITY'
                               software_component    = 'S4CORE'
                               application_component = 'RE-FX-BD'
                               state                 = if_ycm_classic_api_list_v2=>co_state-no_api
                               )
                               (
                               file_Id               = '11'
                               api_id                = '21'
                               tadir_object          = 'CLAS'
                               tadir_obj_name        = '/BCV/CL_AUT_AUTHORIZATION'
                               object_type           = 'CLAS'
                               object_key            = '/BCV/CL_AUT_AUTHORIZATION'
                               software_component    = 'S4FND'
                               application_component = 'CA-EPT-BCV'
                               state                 = if_ycm_classic_api_list_v2=>co_state-no_api
                               ) ).
    environment->insert_test_data( i_data = td_classic_apis ).

    " Prepare test data for 'sycm_api_header'
    td_classic_apis_h = value #( (
                                 file_Id     = '10'
                                 url         = 'github.com/file.json'
                                 created     = '20241015101523'
                                 data_type   = cl_ycm_cc_cache_write_api=>co_data_type_classic
                                 )
                                 (
                                 file_Id     = '11'
                                 url         = 'github.com/file2.json'
                                 created     = '20241015101523'
                                 data_type   = cl_ycm_cc_cache_write_api=>co_data_type_classic
                                 ) ).
    environment->insert_test_data( i_data = td_classic_apis_h ).

    " Prepare test data for 'sycm_api_scsr'
    td_classic_apis_s = value #( (
                                 api_id                   = '22'
                                 successor_tadir_object   = 'FUGR'
                                 successor_tadir_obj_name = 'REBD_BAPI_BUILDING'
                                 successor_object_type    = 'FUNC'
                                 successor_object_key     = 'BAPI_RE_BU_GET_DETAIL'
                                 )
                                 (
                                 api_id                   = '23'
                                 successor_tadir_object   = 'FUGR'
                                 successor_tadir_obj_name = 'REBD_BAPI_BUS_ENTITY'
                                 successor_object_type    = 'FUNC'
                                 successor_object_key     = 'BAPI_RE_BE_GET_DETAIL'
                                 )
                                 (
                                 api_id                   = '23'
                                 successor_tadir_object   = 'FUGR'
                                 successor_tadir_obj_name = 'REBD_BAPI_BUS_ENTITY2'
                                 successor_object_type    = 'FUNC'
                                 successor_object_key     = 'BAPI_RE_BE_GET_DETAIL2'
                                 ) ).
    environment->insert_test_data( i_data = td_classic_apis_s ).

    " Prepare test data for 'sycm_api_label'
    td_classic_apis_l = value #( (
                                 api_id     = '20'
                                 label_name = 'remote-enabled'
                                 ) ).
    environment->insert_test_data( i_data = td_classic_apis_l ).

  endmethod.

  method insert_mock_data_release.
    data:
      td_release_apis   type standard table of sycm_api_cache with empty key,
      td_release_apis_h type standard table of sycm_api_header with empty key,
      td_release_apis_s type standard table of sycm_api_scsr with empty key.

    " Prepare test data for 'sycm_api_cache'
    td_release_apis = value #( (
                               file_Id               = '30'
                               api_id                = '40'
                               tadir_object          = 'DDLS'
                               tadir_obj_name        = 'C_ANALYZESUPLRUTILZNCUBE'
                               object_type           = 'CDS_STOB'
                               object_key            = 'C_ANALYZESUPLRUTILZNCUBE'
                               software_component    = 'SAPSCORE'
                               application_component = 'MM-PUR-ANA'
                               state                 = if_aff_released_check_objs=>co_release_state-released
                               )
                               (
                               file_Id               = '30'
                               api_id                = '42'
                               tadir_object          = 'CHKV'
                               tadir_obj_name        = 'SAP_CP_READINESS'
                               object_type           = 'CHKV'
                               object_key            = 'SAP_CP_READINESS'
                               software_component    = 'SAP_BASIS'
                               application_component = 'BC-DWB-TOO-ATF'
                               state                 = if_aff_released_check_objs=>co_release_state-deprecated
                               )
                               (
                               file_Id               = '30'
                               api_id                = '43'
                               tadir_object          = 'CLAS'
                               tadir_obj_name        = 'CL_A4C_BC_FACTORY'
                               object_type           = 'CLAS'
                               object_key            = 'CL_A4C_BC_FACTORY'
                               software_component    = 'SAP_CLOUD'
                               application_component = 'BC-CP-ABA-SC'
                               state                 = if_aff_released_check_objs=>co_release_state-deprecated
                               )
                               (
                               file_Id               = '31'
                               api_id                = '41'
                               tadir_object          = 'DDLS'
                               tadir_obj_name        = 'C_ANALYZESUPLRUTILZNCUBE'
                               object_type           = 'CDS_STOB'
                               object_key            = 'C_ANALYZESUPLRUTILZNCUBE'
                               software_component    = 'SAPSCORE'
                               application_component = 'MM-PUR-ANA'
                               state                 = if_aff_released_check_objs=>co_release_state-not_to_be_released
                               ) ).
    environment->insert_test_data( i_data = td_release_apis ).

    " Prepare test data for 'sycm_api_header'
    td_release_apis_h = value #( (
                                 file_Id     = '30'
                                 created     = '20241015101523'
                                 url         = 'github.com/file.json'
                                 data_type   = cl_ycm_cc_cache_write_api=>co_data_type_release
                                 )
                                 (
                                 file_Id     = '31'
                                 created     = '20241015101523'
                                 url         = 'github.com/file.json'
                                 data_type   = cl_ycm_cc_cache_write_api=>co_data_type_release
                                 ) ).
    environment->insert_test_data( i_data = td_release_apis_h ).

    " Prepare test data for 'sycm_api_scsr'
    td_release_apis_s = value #( (
                                 api_id                   = '42'
                                 successor_tadir_object   = 'CHKV'
                                 successor_tadir_obj_name = 'ABAP_CLOUD_READINESS'
                                 successor_object_type    = 'CHKV'
                                 successor_object_key     = 'ABAP_CLOUD_READINESS'
                                 )
                                 (
                                 api_id                   = '43'
                                 successor_tadir_object   = 'CLAS'
                                 successor_tadir_obj_name = 'CL_BCFG_CD_REUSE_API_FACTORY'
                                 successor_object_type    = 'CLAS'
                                 successor_object_key     = 'CL_BCFG_CD_REUSE_API_FACTORY'
                                 )
                                 (
                                 api_id                   = '43'
                                 successor_tadir_object   = 'CLAS'
                                 successor_tadir_obj_name = 'XCO_CP_CTS'
                                 successor_object_type    = 'CLAS'
                                 successor_object_key     = 'XCO_CP_CTS'
                                 ) ).
    environment->insert_test_data( i_data = td_release_apis_s ).

  endmethod.

  method classification_manager_call.
    cl_abap_testdouble=>configure_call( manager_testdouble )->and_expect( )->is_called_once( ).
    manager_testdouble->update_or_download_file( url = 'https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/test/objectClassifications.json' file_type = cl_ycm_cc_classification_mangr=>ty_file_type-classic_file ).

    cut = new #( classification_manager = manager_testdouble
                 url                    = 'https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/test/objectClassifications.json'
                 file_type              = cl_ycm_cc_classification_mangr=>ty_file_type-classic_file ).

    cl_abap_testdouble=>verify_expectations( manager_testdouble ).
  endmethod.

  method r_api_returned.

    data(act) = cut->if_ycm_cc_provider_release_api~get_classifications( value #( ( trobjtype   = 'DDLS'
                                                                                    sobj_name   = 'C_ANALYZESUPLRUTILZNCUBE'
                                                                                    object_type = 'CDS_STOB'
                                                                                    sub_key     = 'C_ANALYZESUPLRUTILZNCUBE' ) ) ).
    cl_abap_unit_assert=>assert_table_contains( line  = value if_aff_released_check_objs=>ty_object_release_info( tadir_object          = 'DDLS'
                                                                                                                  tadir_obj_name        = 'C_ANALYZESUPLRUTILZNCUBE'
                                                                                                                  object_type           = 'CDS_STOB'
                                                                                                                  object_key            = 'C_ANALYZESUPLRUTILZNCUBE'
                                                                                                                  software_component    = 'SAPSCORE'
                                                                                                                  application_component = 'MM-PUR-ANA'
                                                                                                                  state                 = if_aff_released_check_objs=>co_release_state-released
                                                                                                                  successors            = value #( ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method r_api_return_one_successor.

    data(act) = cut->if_ycm_cc_provider_release_api~get_classifications( value #( ( trobjtype   = 'CHKV'
                                                                                    sobj_name   = 'SAP_CP_READINESS'
                                                                                    object_type = 'CHKV'
                                                                                    sub_key     = 'SAP_CP_READINESS' ) ) ).
    cl_abap_unit_assert=>assert_table_contains( line  = value if_aff_released_check_objs=>ty_object_release_info( tadir_object          = 'CHKV'
                                                                                                                  tadir_obj_name        = 'SAP_CP_READINESS'
                                                                                                                  object_type           = 'CHKV'
                                                                                                                  object_key            = 'SAP_CP_READINESS'
                                                                                                                  software_component    = 'SAP_BASIS'
                                                                                                                  application_component = 'BC-DWB-TOO-ATF'
                                                                                                                  state                 = if_aff_released_check_objs=>co_release_state-deprecated
                                                                                                                  successors            = value #( ( tadir_object   = 'CHKV'
                                                                                                                                                     tadir_obj_name = 'ABAP_CLOUD_READINESS'
                                                                                                                                                     object_type    = 'CHKV'
                                                                                                                                                     object_key     = 'ABAP_CLOUD_READINESS' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method r_api_return_mltpl_successor.

    data(act) = cut->if_ycm_cc_provider_release_api~get_classifications( value #( ( trobjtype   = 'CLAS'
                                                                                    sobj_name   = 'CL_A4C_BC_FACTORY'
                                                                                    object_type = 'CLAS'
                                                                                    sub_key     = 'CL_A4C_BC_FACTORY' ) ) ).
    cl_abap_unit_assert=>assert_table_contains( line  = value if_aff_released_check_objs=>ty_object_release_info( tadir_object          = 'CLAS'
                                                                                                                  tadir_obj_name        = 'CL_A4C_BC_FACTORY'
                                                                                                                  object_type           = 'CLAS'
                                                                                                                  object_key            = 'CL_A4C_BC_FACTORY'
                                                                                                                  software_component    = 'SAP_CLOUD'
                                                                                                                  application_component = 'BC-CP-ABA-SC'
                                                                                                                  state                 = if_aff_released_check_objs=>co_release_state-deprecated
                                                                                                                  successors            = value #( ( tadir_object   = 'CLAS'
                                                                                                                                                     tadir_obj_name = 'CL_BCFG_CD_REUSE_API_FACTORY'
                                                                                                                                                     object_type    = 'CLAS'
                                                                                                                                                     object_key     = 'CL_BCFG_CD_REUSE_API_FACTORY' )
                                                                                                                                                   ( tadir_object   = 'CLAS'
                                                                                                                                                     tadir_obj_name = 'XCO_CP_CTS'
                                                                                                                                                     object_type    = 'CLAS'
                                                                                                                                                     object_key     = 'XCO_CP_CTS' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method r_api_search_mltpl_apis.

    data(act) = cut->if_ycm_cc_provider_release_api~get_classifications( value #( ( trobjtype   = 'CHKV'
                                                                                    sobj_name   = 'SAP_CP_READINESS'
                                                                                    object_type = 'CHKV'
                                                                                    sub_key     = 'SAP_CP_READINESS' )
                                                                                  ( trobjtype   = 'CLAS'
                                                                                    sobj_name   = 'CL_A4C_BC_FACTORY'
                                                                                    object_type = 'CLAS'
                                                                                    sub_key     = 'CL_A4C_BC_FACTORY' ) ) ).

    loop at act assigning field-symbol(<actual_response>).
      sort <actual_response>-successors by tadir_obj_name. "#EC CI_SORTLOOP
    endloop.

    cl_abap_unit_assert=>assert_table_contains( line  = value if_aff_released_check_objs=>ty_object_release_info( tadir_object          = 'CHKV'
                                                                                                                  tadir_obj_name        = 'SAP_CP_READINESS'
                                                                                                                  object_type           = 'CHKV'
                                                                                                                  object_key            = 'SAP_CP_READINESS'
                                                                                                                  software_component    = 'SAP_BASIS'
                                                                                                                  application_component = 'BC-DWB-TOO-ATF'
                                                                                                                  state                 = if_aff_released_check_objs=>co_release_state-deprecated
                                                                                                                  successors            = value #( ( tadir_object   = 'CHKV'
                                                                                                                                                     tadir_obj_name = 'ABAP_CLOUD_READINESS'
                                                                                                                                                     object_type    = 'CHKV'
                                                                                                                                                     object_key     = 'ABAP_CLOUD_READINESS' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_table_contains( line  = value if_aff_released_check_objs=>ty_object_release_info( tadir_object          = 'CLAS'
                                                                                                                  tadir_obj_name        = 'CL_A4C_BC_FACTORY'
                                                                                                                  object_type           = 'CLAS'
                                                                                                                  object_key            = 'CL_A4C_BC_FACTORY'
                                                                                                                  software_component    = 'SAP_CLOUD'
                                                                                                                  application_component = 'BC-CP-ABA-SC'
                                                                                                                  state                 = if_aff_released_check_objs=>co_release_state-deprecated
                                                                                                                  successors            = value #( ( tadir_object   = 'CLAS'
                                                                                                                                                     tadir_obj_name = 'CL_BCFG_CD_REUSE_API_FACTORY'
                                                                                                                                                     object_type    = 'CLAS'
                                                                                                                                                     object_key     = 'CL_BCFG_CD_REUSE_API_FACTORY' )
                                                                                                                                                   ( tadir_object   = 'CLAS'
                                                                                                                                                     tadir_obj_name = 'XCO_CP_CTS'
                                                                                                                                                     object_type    = 'CLAS'
                                                                                                                                                     object_key     = 'XCO_CP_CTS' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method c_api_returned.

    data(act) = cut->if_ycm_cc_provider_classic_api~get_classifications( value #( ( trobjtype   = 'CLAS'
                                                                                    sobj_name   = '/BCV/CL_AUT_AUTHORIZATION'
                                                                                    object_type = 'CLAS'
                                                                                    sub_key     = '/BCV/CL_AUT_AUTHORIZATION' ) ) ).
    cl_abap_unit_assert=>assert_table_contains( line  = value if_ycm_classic_api_list_v2=>ty_object_classification( tadir_object          = 'CLAS'
                                                                                                                    tadir_obj_name        = '/BCV/CL_AUT_AUTHORIZATION'
                                                                                                                    object_type           = 'CLAS'
                                                                                                                    object_key            = '/BCV/CL_AUT_AUTHORIZATION'
                                                                                                                    software_component    = 'S4FND'
                                                                                                                    application_component = 'CA-EPT-BCV'
                                                                                                                    state                 = if_ycm_classic_api_list_v2=>co_state-classic_api
                                                                                                                    successors            = value #( )
                                                                                                                    labels                = value #( ( if_ycm_classic_api_list_v2=>co_labels-remote_enabled ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method c_api_return_one_successor.

    data(act) = cut->if_ycm_cc_provider_classic_api~get_classifications( value #( ( trobjtype   = 'CLAS'
                                                                                    sobj_name   = 'CF_REBD_BUILDING'
                                                                                    object_type = 'CLAS'
                                                                                    sub_key     = 'CF_REBD_BUILDING' ) ) ).
    cl_abap_unit_assert=>assert_table_contains( line  = value if_ycm_classic_api_list_v2=>ty_object_classification( tadir_object          = 'CLAS'
                                                                                                                    tadir_obj_name        = 'CF_REBD_BUILDING'
                                                                                                                    object_type           = 'CLAS'
                                                                                                                    object_key            = 'CF_REBD_BUILDING'
                                                                                                                    software_component    = 'S4CORE'
                                                                                                                    application_component = 'RE-FX-BD'
                                                                                                                    state                 = if_ycm_classic_api_list_v2=>co_state-no_api
                                                                                                                    successors            = value #( ( tadir_object   = 'FUGR'
                                                                                                                                                       tadir_obj_name = 'REBD_BAPI_BUILDING'
                                                                                                                                                       object_type    = 'FUNC'
                                                                                                                                                       object_key     = 'BAPI_RE_BU_GET_DETAIL' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method c_api_return_mltpl_successor.

    data(act) = cut->if_ycm_cc_provider_classic_api~get_classifications( value #( ( trobjtype   = 'CLAS'
                                                                                    sobj_name   = 'CF_REBD_BUSINESS_ENTITY'
                                                                                    object_type = 'CLAS'
                                                                                    sub_key     = 'CF_REBD_BUSINESS_ENTITY' ) ) ).

    cl_abap_unit_assert=>assert_table_contains( line  = value if_ycm_classic_api_list_v2=>ty_object_classification( tadir_object          = 'CLAS'
                                                                                                                    tadir_obj_name        = 'CF_REBD_BUSINESS_ENTITY'
                                                                                                                    object_type           = 'CLAS'
                                                                                                                    object_key            = 'CF_REBD_BUSINESS_ENTITY'
                                                                                                                    software_component    = 'S4CORE'
                                                                                                                    application_component = 'RE-FX-BD'
                                                                                                                    state                 = if_ycm_classic_api_list_v2=>co_state-no_api
                                                                                                                    successors            = value #( ( tadir_object   = 'FUGR'
                                                                                                                                                       tadir_obj_name = 'REBD_BAPI_BUS_ENTITY'
                                                                                                                                                       object_type    = 'FUNC'
                                                                                                                                                       object_key     = 'BAPI_RE_BE_GET_DETAIL' )
                                                                                                                                                     ( tadir_object   = 'FUGR'
                                                                                                                                                       tadir_obj_name = 'REBD_BAPI_BUS_ENTITY2'
                                                                                                                                                       object_type    = 'FUNC'
                                                                                                                                                       object_key     = 'BAPI_RE_BE_GET_DETAIL2' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method c_api_search_mltpl_apis.

    data(act) = cut->if_ycm_cc_provider_classic_api~get_classifications( value #( ( trobjtype   = 'CLAS'
                                                                                    sobj_name   = 'CF_REBD_BUSINESS_ENTITY'
                                                                                    object_type = 'CLAS'
                                                                                    sub_key     = 'CF_REBD_BUSINESS_ENTITY' )
                                                                                  ( trobjtype   = 'CLAS'
                                                                                    sobj_name   = 'CF_REBD_BUILDING'
                                                                                    object_type = 'CLAS'
                                                                                    sub_key     = 'CF_REBD_BUILDING' ) ) ).

    loop at act assigning field-symbol(<actual_response>).
      sort <actual_response>-successors by tadir_obj_name. "#EC CI_SORTLOOP
    endloop.

    cl_abap_unit_assert=>assert_table_contains( line  = value if_ycm_classic_api_list_v2=>ty_object_classification( tadir_object          = 'CLAS'
                                                                                                                    tadir_obj_name        = 'CF_REBD_BUSINESS_ENTITY'
                                                                                                                    object_type           = 'CLAS'
                                                                                                                    object_key            = 'CF_REBD_BUSINESS_ENTITY'
                                                                                                                    software_component    = 'S4CORE'
                                                                                                                    application_component = 'RE-FX-BD'
                                                                                                                    state                 = if_ycm_classic_api_list_v2=>co_state-no_api
                                                                                                                    successors            = value #( ( tadir_object   = 'FUGR'
                                                                                                                                                       tadir_obj_name = 'REBD_BAPI_BUS_ENTITY'
                                                                                                                                                       object_type    = 'FUNC'
                                                                                                                                                       object_key     = 'BAPI_RE_BE_GET_DETAIL' )
                                                                                                                                                     ( tadir_object   = 'FUGR'
                                                                                                                                                       tadir_obj_name = 'REBD_BAPI_BUS_ENTITY2'
                                                                                                                                                       object_type    = 'FUNC'
                                                                                                                                                       object_key     = 'BAPI_RE_BE_GET_DETAIL2' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_table_contains( line  = value if_ycm_classic_api_list_v2=>ty_object_classification( tadir_object          = 'CLAS'
                                                                                                                    tadir_obj_name        = 'CF_REBD_BUILDING'
                                                                                                                    object_type           = 'CLAS'
                                                                                                                    object_key            = 'CF_REBD_BUILDING'
                                                                                                                    software_component    = 'S4CORE'
                                                                                                                    application_component = 'RE-FX-BD'
                                                                                                                    state                 = if_ycm_classic_api_list_v2=>co_state-no_api
                                                                                                                    successors            = value #( ( tadir_object   = 'FUGR'
                                                                                                                                                       tadir_obj_name = 'REBD_BAPI_BUILDING'
                                                                                                                                                       object_type    = 'FUNC'
                                                                                                                                                       object_key     = 'BAPI_RE_BU_GET_DETAIL' ) ) )
                                                table = act ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method swc_are_returned.
    data(act) = cut->if_ycm_cc_provider_release_api~get_known_sw_components( ).

    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( act ) ).
    cl_abap_unit_assert=>assert_table_contains( line = conv dlvunit( 'SAPSCORE' ) table = act ).
    cl_abap_unit_assert=>assert_table_contains( line = conv dlvunit( 'SAP_CLOUD' ) table = act ).
    cl_abap_unit_assert=>assert_table_contains( line = conv dlvunit( 'SAP_BASIS' ) table = act ).
  endmethod.

  method class_teardown.
    environment->destroy( ).
  endmethod.

endclass.
