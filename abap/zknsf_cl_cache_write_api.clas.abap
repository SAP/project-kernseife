CLASS zknsf_cl_cache_write_api DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      tt_api_cache      TYPE STANDARD TABLE OF sycm_api_cache WITH DEFAULT KEY .
    TYPES:
      tt_api_labels     TYPE STANDARD TABLE OF sycm_api_label WITH DEFAULT KEY .
    TYPES:
      tt_api_successors TYPE STANDARD TABLE OF sycm_api_scsr WITH DEFAULT KEY .
    TYPES:
    tt_ratings          TYPE STANDARD TABLE OF zknsf_ratings WITH DEFAULT KEY.

    CONSTANTS co_data_type_custom TYPE c VALUE 'K' ##NO_TEXT.

    METHODS write_custom
      IMPORTING
        !imported_objects TYPE zknsf_if_api_v1=>ty_main
        !url              TYPE string
        !source           TYPE string
        !commit_hash      TYPE string OPTIONAL
        !last_git_check   TYPE timestamp OPTIONAL
        !uploader         TYPE uname OPTIONAL
      RAISING
        cx_ycm_cc_provider_error
        cx_uuid_error .
    METHODS url_exists
      IMPORTING
        !url          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool .
protected section.
private section.

  methods CREATE_HEADER
    importing
      !URL type STRING
      !DATA_TYPE type C
      !SOURCE type STRING
      !COMMIT_HASH type STRING optional
      !LAST_GIT_CHECK type TIMESTAMP optional
      !UPLOADER type UNAME optional
    returning
      value(RESULT) type SYCM_API_HEADER
    raising
      CX_UUID_ERROR .
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


  method URL_EXISTS.
    select single @abap_true from zknsf_api_header where url = @url into @result.
  endmethod.


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
ENDCLASS.
