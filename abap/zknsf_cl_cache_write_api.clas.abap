CLASS zknsf_cl_cache_write_api DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      tt_ratings         TYPE STANDARD TABLE OF zknsf_ratings WITH DEFAULT KEY .
    TYPES:
      tt_api_cache      TYPE STANDARD TABLE OF zknsf_api_cache WITH DEFAULT KEY .
    TYPES:
      tt_api_labels     TYPE STANDARD TABLE OF zknsf_api_label WITH DEFAULT KEY .
    TYPES:
      tt_api_successors TYPE STANDARD TABLE OF zknsf_api_scsr WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_api_file,
        file_id        TYPE guid,
        url            TYPE char140,
        etag           TYPE string,
        last_git_check TYPE string,
        created        TYPE string,
        data_type      TYPE string,
        source         TYPE char5,
        uploader       TYPE char12,
      END OF ty_api_file .
    TYPES:
      BEGIN OF ty_api,
        api_id                TYPE guid,
        file_id               TYPE guid,
        tadir_object          TYPE trobjtype,
        tadir_obj_name        TYPE sobj_name,
        object_type           TYPE sych_object_type,
        object_key            TYPE sych_object_sub_key,
        software_component    TYPE dlvunit,
        application_component TYPE ufps_posid,
        state                 TYPE c LENGTH 30,
        successors            TYPE string,
        labels                TYPE string,
      END OF ty_api .
    TYPES:
      BEGIN OF ty_scsr,
        api_id         TYPE guid,
        tadir_object   TYPE trobjtype,
        tadir_obj_name TYPE sobj_name,
        object_type    TYPE sych_object_type,
        object_key     TYPE sych_object_sub_key,
      END OF ty_scsr .
    TYPES:
      api_files  TYPE STANDARD TABLE OF ty_api_file WITH EMPTY KEY .
    TYPES:
      apis       TYPE STANDARD TABLE OF ty_api WITH EMPTY KEY .
    TYPES:
      successors TYPE STANDARD TABLE OF ty_scsr WITH EMPTY KEY .

    CONSTANTS co_data_type_custom TYPE c VALUE 'K' ##NO_TEXT.

    METHODS write_custom
      IMPORTING
        !imported_objects TYPE zknsf_if_api_v1=>ty_main
        !url              TYPE string
        !source           TYPE string
        !commit_hash      TYPE string OPTIONAL
        !last_git_check   TYPE timestamp OPTIONAL
        !uploader         TYPE syuname OPTIONAL
      RAISING
        cx_ycm_cc_provider_error
        cx_uuid_error .
    METHODS url_exists
      IMPORTING
        !url          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool .
    METHODS get_custom_apis_aff
      IMPORTING
        !file_id      TYPE guid
      RETURNING
        VALUE(result) TYPE if_ycm_classic_api_list_v2=>ty_main .
    METHODS get_api_files
      RETURNING
        VALUE(result) TYPE api_files .
    METHODS get_apis
      IMPORTING
        !file_id      TYPE guid
      RETURNING
        VALUE(result) TYPE apis .
    METHODS get_successors
      IMPORTING
        !api_id       TYPE guid
      RETURNING
        VALUE(result) TYPE successors .
    METHODS delete_all .
    METHODS delete_file
      IMPORTING
        !url TYPE string .
    METHODS get_display_name_of_state
      IMPORTING
        !old_state    TYPE char30
      RETURNING
        VALUE(result) TYPE string .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA:
      ratings TYPE SORTED TABLE OF zknsf_i_ratings WITH NON-UNIQUE  KEY primary_key COMPONENTS code .

    METHODS create_header
      IMPORTING
        !url            TYPE string
        !data_type      TYPE c
        !source         TYPE string
        !commit_hash    TYPE string OPTIONAL
        !last_git_check TYPE timestamp OPTIONAL
        !uploader       TYPE syuname OPTIONAL
      RETURNING
        VALUE(result)   TYPE zknsf_api_header
      RAISING
        cx_uuid_error .
ENDCLASS.



CLASS ZKNSF_CL_CACHE_WRITE_API IMPLEMENTATION.


  METHOD create_header.
    GET TIME STAMP FIELD DATA(date).
    RETURN VALUE zknsf_api_header( data_type      = data_type
                                   created        = date
                                   file_id        = cl_system_uuid=>create_uuid_x16_static( )
                                   url            = url
                                   commit_hash    = commit_hash
                                   last_git_check = last_git_check
                                   source         = source
                                   uploader       = uploader ).
  ENDMETHOD.


  METHOD url_exists.
    SELECT SINGLE @abap_true FROM zknsf_api_header WHERE url = @url INTO @result.
  ENDMETHOD.


  METHOD write_custom.

    IF url_exists( url ).
      RAISE EXCEPTION NEW cx_ycm_cc_provider_error( msgno = '003' ).
    ENDIF.

    DATA(header) = create_header( url            = url
                                  data_type      = co_data_type_custom
                                  commit_hash    = commit_hash
                                  last_git_check = last_git_check
                                  source         = source
                                  uploader       = uploader
                                  ).

    DATA: apis           TYPE tt_api_cache,
          api_labels     TYPE tt_api_labels,
          api_successors TYPE tt_api_successors,
          ratings        TYPE tt_ratings.

    LOOP AT imported_objects-object_classifications ASSIGNING FIELD-SYMBOL(<api_row>).
      DATA(api) = VALUE zknsf_api_cache( file_id = header-file_id
                                         api_id  = cl_system_uuid=>create_uuid_x16_static( ) ).

      MOVE-CORRESPONDING <api_row> TO api.
      INSERT api INTO TABLE apis.

      INSERT LINES OF VALUE tt_api_labels( FOR label IN <api_row>-labels ( api_id     = api-api_id
                                                                           label_name = label ) ) INTO TABLE api_labels.
      INSERT LINES OF VALUE tt_api_successors( FOR successor IN <api_row>-successors ( api_id                   = api-api_id
                                                                                       successor_tadir_object   = successor-tadir_object
                                                                                       successor_tadir_obj_name = successor-tadir_obj_name
                                                                                       successor_object_type    = successor-object_type
                                                                                       successor_object_key     = successor-object_key ) ) INTO TABLE api_successors.
    ENDLOOP.

    SORT api_successors.
    DELETE ADJACENT DUPLICATES FROM api_successors.

    INSERT INTO zknsf_api_header      VALUES header.
    INSERT      zknsf_api_cache       FROM TABLE apis.
    INSERT      zknsf_api_scsr        FROM TABLE api_successors.
    INSERT      zknsf_api_label       FROM TABLE api_labels.

    LOOP AT imported_objects-ratings ASSIGNING FIELD-SYMBOL(<rating>).
      DATA(rating) = VALUE zknsf_ratings( ).
      MOVE-CORRESPONDING <rating> TO rating.
      INSERT rating INTO TABLE ratings.
    ENDLOOP.

    INSERT zknsf_ratings FROM TABLE ratings.
  ENDMETHOD.


  METHOD delete_all.
    DELETE FROM zknsf_api_cache.                        "#EC CI_NOWHERE
    DELETE FROM zknsf_api_header.                       "#EC CI_NOWHERE
    DELETE FROM zknsf_api_label.                        "#EC CI_NOWHERE
    DELETE FROM zknsf_api_scsr.                         "#EC CI_NOWHERE

    DELETE FROM zknsf_ratings.                          "#EC CI_NOWHERE
    CLEAR ratings.
  ENDMETHOD.


  METHOD delete_file.
    SELECT SINGLE file_id FROM zknsf_api_header WHERE url = @url INTO @DATA(file_id) ##WARN_OK. "#EC CI_NOORDER

    DELETE FROM zknsf_api_label WHERE api_id IN ( SELECT api_id FROM zknsf_api_cache WHERE file_id = @file_id ).
    DELETE FROM zknsf_api_scsr WHERE api_id IN ( SELECT api_id FROM zknsf_api_cache WHERE file_id = @file_id ).
    DELETE FROM zknsf_api_cache WHERE file_id = @file_id.
    DELETE FROM zknsf_api_header WHERE file_id = @file_id.

    " Always also delete the Ratings...
    DELETE FROM zknsf_ratings.                          "#EC CI_NOWHERE
    CLEAR ratings. " Clear Buffer
  ENDMETHOD.


  METHOD get_apis.
    SELECT * FROM zknsf_api_cache  WHERE file_id = @file_id INTO TABLE @DATA(db_apis). "#EC CI_NOWHERE
    SELECT * FROM zknsf_api_header WHERE file_id = @file_id INTO TABLE @DATA(db_api_file). "#EC CI_ALL_FIELDS_NEEDED


    DATA:
      labels     TYPE SORTED TABLE OF zknsf_api_label WITH NON-UNIQUE  KEY primary_key COMPONENTS api_id,
      successors TYPE SORTED TABLE OF zknsf_api_scsr WITH NON-UNIQUE  KEY primary_key COMPONENTS api_id.
    SELECT * FROM zknsf_api_label INTO TABLE labels. "#EC CI_NOWHERE CI_ALL_FIELDS_NEEDED
    SELECT api_id FROM zknsf_api_scsr INTO TABLE @successors. "#EC CI_NOWHERE

    DATA api_data TYPE ty_api.
    LOOP AT db_apis ASSIGNING FIELD-SYMBOL(<api>).
      MOVE-CORRESPONDING <api> TO api_data.

      api_data-state = get_display_name_of_state( api_data-state ).

      DATA(file_instance) = VALUE #( db_api_file[ 1 ] OPTIONAL ).

      DATA label_text TYPE STANDARD TABLE OF string40.
      CLEAR label_text.
      LOOP AT labels ASSIGNING FIELD-SYMBOL(<label>) WHERE api_id = api_data-api_id.
        APPEND <label>-label_name TO label_text.
      ENDLOOP.

      api_data-labels = concat_lines_of( table = label_text sep = `, ` ).

      api_data-successors = lines( FILTER #( successors WHERE api_id = api_data-api_id ) ).

      APPEND api_data TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_api_files.
    SELECT * FROM zknsf_api_header INTO TABLE @DATA(db_files). "#EC CI_NOWHERE

    DATA data_file LIKE LINE OF result.
    LOOP AT db_files ASSIGNING FIELD-SYMBOL(<file>).
      MOVE-CORRESPONDING <file> TO data_file.

      data_file-data_type = 'Kernseife'(001).

      APPEND data_file TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_custom_apis_aff.
    DATA classic_api LIKE LINE OF result-object_classifications.
    SELECT SINGLE data_type FROM zknsf_api_header WHERE file_id = @file_id INTO @DATA(api_file_data_type).
    IF api_file_data_type <> co_data_type_custom.
      RETURN. "no custom api
    ENDIF.

    SELECT * FROM zknsf_api_cache WHERE file_id = @file_id INTO TABLE @DATA(db_apis). "#EC CI_NOWHERE
    result-format_version = if_ycm_classic_api_list_v2=>co_format_version.
    LOOP AT db_apis ASSIGNING FIELD-SYMBOL(<api>).
      CLEAR classic_api.
      MOVE-CORRESPONDING <api> TO classic_api.

      SELECT label_name FROM zknsf_api_label WHERE api_id = @<api>-api_id INTO @DATA(db_label). "#EC CI_NOWHERE
        INSERT CONV #( db_label ) INTO TABLE classic_api-labels.
      ENDSELECT.

      SELECT * FROM zknsf_api_scsr WHERE api_id = @<api>-api_id INTO  @DATA(db_successor).
        INSERT VALUE #( tadir_object   = db_successor-successor_tadir_object
                        tadir_obj_name = db_successor-successor_tadir_obj_name
                        object_type    = db_successor-successor_object_type
                        object_key     = db_successor-successor_object_key ) INTO TABLE classic_api-successors.
      ENDSELECT.
      INSERT classic_api INTO TABLE result-object_classifications.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_display_name_of_state.
    CLEAR result.
    IF ratings IS INITIAL.
      SELECT * FROM   zknsf_i_ratings  INTO TABLE @ratings.
    ENDIF.

    TRY.
        result = ratings[ code = old_state ]-title.
      CATCH cx_sy_itab_line_not_found.
        RETURN 'Error'.
    ENDTRY.

  ENDMETHOD.


  METHOD get_successors.
    SELECT * FROM zknsf_api_scsr WHERE zknsf_api_scsr~api_id = @api_id INTO TABLE @DATA(db_successors).

    result = CORRESPONDING #(
              db_successors MAPPING api_id = api_id
              object_key = successor_object_key
              object_type = successor_object_type
              tadir_object = successor_tadir_object
              tadir_obj_name = successor_tadir_obj_name
             ).
  ENDMETHOD.
ENDCLASS.
