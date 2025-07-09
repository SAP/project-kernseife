class ZKNSF_CL_USAGE_PREPROCESSOR definition
  public
  inheriting from CL_YCM_CC_USAGE_PREPROCESSOR
  create public .

public section.
protected section.

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
ENDCLASS.
