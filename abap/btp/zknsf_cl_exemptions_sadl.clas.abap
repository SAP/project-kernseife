CLASS zknsf_cl_exemptions_sadl DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit_calc_element_read.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_user,
             user_id   TYPE cl_abap_context_info=>ty_user_name,
             user_name TYPE string,
           END OF ty_user.

    DATA user_cache TYPE SORTED TABLE OF ty_user WITH UNIQUE KEY  user_id.

    METHODS:
      get_user_name IMPORTING user_id          TYPE cl_abap_context_info=>ty_user_name
                    RETURNING VALUE(user_name) TYPE string.
ENDCLASS.



CLASS zknsf_cl_exemptions_sadl IMPLEMENTATION.
  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA result TYPE zknsf_i_exemptions.
    LOOP AT it_original_data ASSIGNING FIELD-SYMBOL(<excemption>).
      READ TABLE ct_calculated_data ASSIGNING FIELD-SYMBOL(<fs_calculated_data>) INDEX sy-tabix.

      ASSIGN COMPONENT 'APPLICANTUSERID' OF STRUCTURE <excemption> TO FIELD-SYMBOL(<applicantuserid>).
      IF sy-subrc EQ 0 AND <applicantuserid> IS ASSIGNED.
        ASSIGN COMPONENT 'APPLICANTUSERNAME' OF STRUCTURE <fs_calculated_data> TO FIELD-SYMBOL(<applicantusername>).
        IF sy-subrc EQ 0 AND <applicantusername> IS ASSIGNED.
          " Read Username
          IF <applicantuserid> IS INITIAL.
            CLEAR <applicantusername>.
          ELSE.
            <applicantusername> = get_user_name( user_id = <applicantuserid> ).
          ENDIF.
        ENDIF.
      ENDIF.

      ASSIGN COMPONENT 'APPROVERUSERID' OF STRUCTURE <excemption> TO FIELD-SYMBOL(<approveruserid>).
      IF sy-subrc EQ 0 AND <approveruserid> IS ASSIGNED.
        ASSIGN COMPONENT 'APPROVERUSERNAME' OF STRUCTURE <fs_calculated_data> TO FIELD-SYMBOL(<approverusername>).
        IF sy-subrc EQ 0 AND <approverusername> IS ASSIGNED.
          " Read Username
          IF <approveruserid> IS INITIAL.
            CLEAR <approverusername>.
          ELSE.
            <approverusername> = get_user_name( user_id = <approveruserid> ).
          ENDIF.
        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info ##NEEDED.
  ENDMETHOD.

  METHOD get_user_name.
    CLEAR user_name.

    READ TABLE user_cache ASSIGNING FIELD-SYMBOL(<user_cache>) WITH KEY user_id = user_id.
    IF sy-subrc = 0.
      RETURN <user_cache>-user_name.
    ENDIF.

    SELECT SINGLE username FROM zknsf_i_user_name INTO @user_name WHERE userid = @user_id.
    IF sy-subrc = 0.
      INSERT VALUE #( user_id = user_id user_name = user_name ) INTO TABLE user_cache.
    ENDIF.
    RETURN user_name.

  ENDMETHOD.
ENDCLASS.
