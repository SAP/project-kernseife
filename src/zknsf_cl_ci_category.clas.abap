class ZKNSF_CL_CI_CATEGORY definition
  public
  inheriting from CL_CI_CATEGORY_ROOT
  final
  create public .

public section.

  methods CONSTRUCTOR .
ENDCLASS.



CLASS ZKNSF_CL_CI_CATEGORY IMPLEMENTATION.


  method CONSTRUCTOR .

    super->constructor( ).
    description = 'Kernseife Open-Source'(000).
    category    = 'CL_CI_CATEGORY_TOP'.
    position    = '001'.
    clear has_documentation.

  endmethod.
ENDCLASS.
