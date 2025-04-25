class ltcl_unit_test definition final for testing duration short risk level harmless.

  public section.
    interfaces:
      if_ycm_classic_api_list_v2,
      if_aff_released_check_objs.

    aliases:
     tt_classic_api for if_ycm_classic_api_list_v2~ty_main,
     tt_release_api for if_aff_released_check_objs~ty_main.

  private section.
    class-methods:
      class_setup,
      class_teardown.

    class-data:
      environment       type ref to if_osql_test_environment,
      classic_mock_data type tt_classic_api-object_classifications,
      release_mock_data type tt_release_api-object_release_info.

    methods:
      setup,
      classic_not_inserted_twice          for testing raising cx_static_check,
      classic_header_is_inserted          for testing raising cx_static_check,
      classic_apis_are_inserted           for testing raising cx_static_check,
      classic_successors_inserted         for testing raising cx_static_check,
      classic_labels_inserted             for testing raising cx_static_check,
      release_not_inserted_twice          for testing raising cx_static_check,
      release_header_is_inserted          for testing raising cx_static_check,
      release_apis_are_inserted           for testing raising cx_static_check,
      release_successors_inserted         for testing raising cx_static_check,
      two_funcs_can_be_inserted           for testing raising cx_static_check,
      classic_two_funcs_can_be_sccsr      for testing raising cx_static_check,
      release_two_funcs_can_be_sccsr      for testing raising cx_static_check,
      classic_dplct_scsrs_not_insrtd      for testing raising cx_static_check,
      release_dplct_scsrs_not_insrtd      for testing raising cx_static_check.

    data cut type ref to cl_ycm_cc_cache_write_api.

endclass.


class ltcl_unit_test implementation.

  method setup.
    cut = new #( ).
    environment->clear_doubles( ).
  endmethod.

  method class_setup.
    environment = cl_osql_test_environment=>create( value #( ( 'SYCM_API_CACHE' )
                                                             ( 'SYCM_API_HEADER' )
                                                             ( 'SYCM_API_LABEL' )
                                                             ( 'SYCM_API_SCSR' ) ) ).

    classic_mock_data = value tt_classic_api-object_classifications( ( tadir_object          = 'CLAS'
                                                                       tadir_obj_name        = 'CL_BAL_LOGGING'
                                                                       object_type           = 'CLAS'
                                                                       object_key            = 'CL_BAL_LOGGING'
                                                                       software_component    = 'SAP_BASIS'
                                                                       application_component = 'BC-SRV-BAL'
                                                                       state                 = if_ycm_classic_api_list_v2~co_state-classic_api
                                                                       labels                = value #( ( `remote-enabled` ) ( `transactional-consistent` ) )
                                                                       successors            = value #( ( tadir_object   = 'CLAS'
                                                                                                          tadir_obj_name = 'CL_BALI_LOG'
                                                                                                          object_type    = 'CLAS'
                                                                                                          object_key     = 'CL_BALI_LOG' )
                                                                                                        ( tadir_object   = 'CLAS'
                                                                                                          tadir_obj_name = 'CL_BALI_LOG_2'
                                                                                                          object_type    = 'CLAS'
                                                                                                          object_key     = 'CL_BALI_LOG_2' ) ) )
                                                                     ( tadir_object          = 'FUGR'
                                                                       tadir_obj_name        = 'SUNI'
                                                                       object_type           = 'FUNC'
                                                                       object_key            = 'FUNCTION_EXISTS'
                                                                       software_component    = 'SAP_BASIS'
                                                                       application_component = 'BC-SRV-BAL'
                                                                       state                 = if_ycm_classic_api_list_v2~co_state-no_api
                                                                       labels                = value #( )
                                                                       successors            = value #( ) ) ).

    release_mock_data = value tt_release_api-object_release_info( ( tadir_object          = 'CLAS'
                                                                    tadir_obj_name        = 'CL_BAL_LOGGING'
                                                                    object_type           = 'CLAS'
                                                                    object_key            = 'CL_BAL_LOGGING'
                                                                    software_component    = 'SAP_BASIS'
                                                                    application_component = 'BC-SRV-BAL'
                                                                    state                 = if_aff_released_check_objs~co_release_state-not_to_be_released
                                                                    successors            = value #( ( tadir_object   = 'CLAS'
                                                                                                       tadir_obj_name = 'CL_BALI_LOG'
                                                                                                       object_type    = 'CLAS'
                                                                                                       object_key     = 'CL_BALI_LOG' )
                                                                                                     ( tadir_object   = 'CLAS'
                                                                                                       tadir_obj_name = 'CL_BALI_LOG_2'
                                                                                                       object_type    = 'CLAS'
                                                                                                       object_key     = 'CL_BALI_LOG_2' ) ) )
                                                                  ( tadir_object          = 'FUGR'
                                                                    tadir_obj_name        = 'SUNI'
                                                                    object_type           = 'FUNC'
                                                                    object_key            = 'FUNCTION_EXISTS'
                                                                    software_component    = 'SAP_BASIS'
                                                                    application_component = 'BC-SRV-BAL'
                                                                    state                 = if_aff_released_check_objs~co_release_state-deprecated
                                                                    successors            = value #( ) ) ).

  endmethod.

  method classic_header_is_inserted.
    cut->write_classic( imported_objects = classic_mock_data
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_header into table @data(actual_header). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( actual_header ) ).
    cl_abap_unit_assert=>assert_not_initial( actual_header[ 1 ]-file_id ).
    cl_abap_unit_assert=>assert_equals( exp = cl_ycm_cc_cache_write_api=>co_data_type_classic act = actual_header[ 1 ]-data_type ).
    cl_abap_unit_assert=>assert_equals( exp = 'github.com/file.json' act = actual_header[ 1 ]-url ).
    cl_abap_unit_assert=>assert_equals( exp = cl_ycm_cc_classification_mangr=>source_local act = actual_header[ 1 ]-source ).
    cl_abap_unit_assert=>assert_not_initial( actual_header[ 1 ]-created ).
  endmethod.

  method classic_apis_are_inserted.
    cut->write_classic( imported_objects = classic_mock_data
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_header into table @data(act_header). "#EC CI_NOWHERE
    select * from sycm_api_cache into table @data(act). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_cache( file_id               = act_header[ 1 ]-file_id
                                                                              api_id                = act[ tadir_obj_name = 'CL_BAL_LOGGING' ]-api_id
                                                                              tadir_object          = 'CLAS'
                                                                              tadir_obj_name        = 'CL_BAL_LOGGING'
                                                                              object_type           = 'CLAS'
                                                                              object_key            = 'CL_BAL_LOGGING'
                                                                              software_component    = 'SAP_BASIS'
                                                                              application_component = 'BC-SRV-BAL'
                                                                              state                 = if_ycm_classic_api_list_v2~co_state-classic_api ) ). "#EC CI_NOORDER
    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_cache( file_id               = act_header[ 1 ]-file_id
                                                                              api_id                = act[ tadir_obj_name = 'SUNI' ]-api_id
                                                                              tadir_object          = 'FUGR'
                                                                              tadir_obj_name        = 'SUNI'
                                                                              object_type           = 'FUNC'
                                                                              object_key            = 'FUNCTION_EXISTS'
                                                                              software_component    = 'SAP_BASIS'
                                                                              application_component = 'BC-SRV-BAL'
                                                                              state                 = if_ycm_classic_api_list_v2~co_state-no_api ) ). "#EC CI_NOORDER
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method classic_successors_inserted.
    cut->write_classic( imported_objects = classic_mock_data
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_cache into table @data(act_apis). "#EC CI_NOWHERE
    select * from sycm_api_scsr into table @data(act).  "#EC CI_NOWHERE

    data(api_id) = act_apis[ tadir_obj_name = 'CL_BAL_LOGGING' ]-api_id.

    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_scsr( api_id                   = api_id
                                                                             successor_tadir_object   = 'CLAS'
                                                                             successor_tadir_obj_name = 'CL_BALI_LOG'
                                                                             successor_object_type    = 'CLAS'
                                                                             successor_object_key     = 'CL_BALI_LOG' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_scsr( api_id                   = api_id
                                                                             successor_tadir_object   = 'CLAS'
                                                                             successor_tadir_obj_name = 'CL_BALI_LOG_2'
                                                                             successor_object_type    = 'CLAS'
                                                                             successor_object_key     = 'CL_BALI_LOG_2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method classic_labels_inserted.
    cut->write_classic( imported_objects = classic_mock_data
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_cache into table @data(act_apis). "#EC CI_NOWHERE
    select * from sycm_api_label into table @data(act). "#EC CI_NOWHERE

    data(api_id) = act_apis[ tadir_obj_name = 'CL_BAL_LOGGING' ]-api_id.

    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_label( api_id     = api_id
                                                                              label_name = 'transactional-consistent' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_label( api_id     = api_id
                                                                              label_name = 'remote-enabled' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method release_header_is_inserted.
    cut->write_release( imported_objects = release_mock_data
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_header into table @data(actual_header). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( actual_header ) ).
    cl_abap_unit_assert=>assert_not_initial( actual_header[ 1 ]-file_id ).
    cl_abap_unit_assert=>assert_equals( exp = cl_ycm_cc_cache_write_api=>co_data_type_release act = actual_header[ 1 ]-data_type ).
    cl_abap_unit_assert=>assert_equals( exp = 'github.com/file.json' act = actual_header[ 1 ]-url ).
    cl_abap_unit_assert=>assert_equals( exp = cl_ycm_cc_classification_mangr=>source_local act = actual_header[ 1 ]-source ).
    cl_abap_unit_assert=>assert_not_initial( actual_header[ 1 ]-created ).
  endmethod.

  method release_apis_are_inserted.
    cut->write_release( imported_objects = release_mock_data
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_header into table @data(act_header). "#EC CI_NOWHERE
    select * from sycm_api_cache into table @data(act). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_cache( file_id               = act_header[ 1 ]-file_id
                                                                              api_id                = act[ tadir_obj_name = 'CL_BAL_LOGGING' ]-api_id
                                                                              tadir_object          = 'CLAS'
                                                                              tadir_obj_name        = 'CL_BAL_LOGGING'
                                                                              object_type           = 'CLAS'
                                                                              object_key            = 'CL_BAL_LOGGING'
                                                                              software_component    = 'SAP_BASIS'
                                                                              application_component = 'BC-SRV-BAL'
                                                                              state                 = if_aff_released_check_objs~co_release_state-not_to_be_released ) ). "#EC CI_NOORDER
    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_cache( file_id               = act_header[ 1 ]-file_id
                                                                              api_id                = act[ tadir_obj_name = 'SUNI' ]-api_id
                                                                              tadir_object          = 'FUGR'
                                                                              tadir_obj_name        = 'SUNI'
                                                                              object_type           = 'FUNC'
                                                                              object_key            = 'FUNCTION_EXISTS'
                                                                              software_component    = 'SAP_BASIS'
                                                                              application_component = 'BC-SRV-BAL'
                                                                              state                 = if_aff_released_check_objs~co_release_state-deprecated ) ). "#EC CI_NOORDER
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method release_successors_inserted.
    cut->write_release( imported_objects = release_mock_data
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_cache into table @data(act_apis). "#EC CI_NOWHERE
    select * from sycm_api_scsr into table @data(act).  "#EC CI_NOWHERE

    data(api_id) = act_apis[ tadir_obj_name = 'CL_BAL_LOGGING' ]-api_id.

    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_scsr( api_id                   = api_id
                                                                             successor_tadir_object   = 'CLAS'
                                                                             successor_tadir_obj_name = 'CL_BALI_LOG'
                                                                             successor_object_type    = 'CLAS'
                                                                             successor_object_key     = 'CL_BALI_LOG' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = act
                                                line  = value sycm_api_scsr( api_id                   = api_id
                                                                             successor_tadir_object   = 'CLAS'
                                                                             successor_tadir_obj_name = 'CL_BALI_LOG_2'
                                                                             successor_object_type    = 'CLAS'
                                                                             successor_object_key     = 'CL_BALI_LOG_2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method classic_not_inserted_twice.

    cut->write_classic( imported_objects = value #( )
                        url              = 'Test Path'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    try.
        cut->write_classic( imported_objects = value #( )
                            url              = 'Test Path'
                            source           = cl_ycm_cc_classification_mangr=>source_local ).
        cl_abap_unit_assert=>fail( ).
      catch cx_ycm_cc_provider_error into data(exception).
        cl_abap_unit_assert=>assert_equals( exp = 'SYCM_CC' act = exception->if_t100_message~t100key-msgid ).
        cl_abap_unit_assert=>assert_equals( exp = '003' act = exception->if_t100_message~t100key-msgno ).
    endtry.

  endmethod.

  method release_not_inserted_twice.

    cut->write_release( imported_objects = value #( )
                        url              = 'Test Path'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    try.
        cut->write_release( imported_objects = value #( )
                            url              = 'Test Path'
                            source           = cl_ycm_cc_classification_mangr=>source_local ).
        cl_abap_unit_assert=>fail( ).
      catch cx_ycm_cc_provider_error into data(exception).
        cl_abap_unit_assert=>assert_equals( exp = 'SYCM_CC' act = exception->if_t100_message~t100key-msgid ).
        cl_abap_unit_assert=>assert_equals( exp = '003' act = exception->if_t100_message~t100key-msgno ).
    endtry.

  endmethod.

  method two_funcs_can_be_inserted.
    data(two_funcs)  = value tt_release_api-object_release_info( ( tadir_object   = 'FUGR'
                                                                   tadir_obj_name = 'GROUP1'
                                                                   object_type    = 'FUNC'
                                                                   object_key     = 'FUNCTION1' )
                                                                 ( tadir_object   = 'FUGR'
                                                                   tadir_obj_name = 'GROUP1'
                                                                   object_type    = 'FUNC'
                                                                   object_key     = 'FUNCTION2' ) ).

    cut->write_release( imported_objects = two_funcs
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_cache into table @data(act). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method classic_two_funcs_can_be_sccsr.
    data(two_funcs)  = value tt_classic_api-object_classifications( ( successors = value #( ( tadir_object   = 'FUGR'
                                                                                              tadir_obj_name = 'GROUP1'
                                                                                              object_type    = 'FUNC'
                                                                                              object_key     = 'FUNCTION1' )
                                                                                            ( tadir_object   = 'FUGR'
                                                                                              tadir_obj_name = 'GROUP1'
                                                                                              object_type    = 'FUNC'
                                                                                              object_key     = 'FUNCTION2' ) ) ) ).

    cut->write_classic( imported_objects = two_funcs
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_scsr into table @data(act). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method release_two_funcs_can_be_sccsr.
    data(two_funcs)  = value tt_release_api-object_release_info( ( successors = value #( ( tadir_object   = 'FUGR'
                                                                                           tadir_obj_name = 'GROUP1'
                                                                                           object_type    = 'FUNC'
                                                                                           object_key     = 'FUNCTION1' )
                                                                                         ( tadir_object   = 'FUGR'
                                                                                           tadir_obj_name = 'GROUP1'
                                                                                           object_type    = 'FUNC'
                                                                                           object_key     = 'FUNCTION2' ) ) ) ).

    cut->write_release( imported_objects = two_funcs
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_scsr into table @data(act). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( act ) ).
  endmethod.

  method classic_dplct_scsrs_not_insrtd.
    data(duplicate_successors)  = value tt_classic_api-object_classifications( ( successors = value #( ( tadir_object   = 'FUGR'
                                                                                                         tadir_obj_name = 'GROUP1'
                                                                                                         object_type    = 'FUNC'
                                                                                                         object_key     = 'FUNCTION1' )
                                                                                                       ( tadir_object   = 'FUGR'
                                                                                                         tadir_obj_name = 'GROUP1'
                                                                                                         object_type    = 'FUNC'
                                                                                                         object_key     = 'FUNCTION1' ) ) ) ).

    cut->write_classic( imported_objects = duplicate_successors
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_scsr into table @data(act). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method release_dplct_scsrs_not_insrtd.
    data(duplicate_successors)  = value tt_release_api-object_release_info( ( successors = value #( ( tadir_object   = 'FUGR'
                                                                                                      tadir_obj_name = 'GROUP1'
                                                                                                      object_type    = 'FUNC'
                                                                                                      object_key     = 'FUNCTION1' )
                                                                                                    ( tadir_object   = 'FUGR'
                                                                                                      tadir_obj_name = 'GROUP1'
                                                                                                      object_type    = 'FUNC'
                                                                                                      object_key     = 'FUNCTION1' ) ) ) ).

    cut->write_release( imported_objects = duplicate_successors
                        url              = 'github.com/file.json'
                        source           = cl_ycm_cc_classification_mangr=>source_local ).

    select * from sycm_api_scsr into table @data(act). "#EC CI_NOWHERE

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act ) ).
  endmethod.

  method class_teardown.
    environment->destroy( ).
  endmethod.

endclass.
