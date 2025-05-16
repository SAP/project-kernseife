class ZKNSF_CL_JSON_COMPAT definition
  public
  final
  create public .

public section.

  interfaces IF_AFF_COMPATIBILITY_HANDLER .
protected section.
private section.
ENDCLASS.



CLASS ZKNSF_CL_JSON_COMPAT IMPLEMENTATION.


  method IF_AFF_COMPATIBILITY_HANDLER~GET_SUPPORTED_FORMAT_VERSIONS.
    result = value #( ( format_version = '1' st_name = 'ZKNSF_XSLT_API_V1'    aff_type = 'ZKNSF_IF_API_V1=>TY_MAIN' ) ).
  endmethod.


  method IF_AFF_COMPATIBILITY_HANDLER~UPGRADE.
    clear output.
  endmethod.
ENDCLASS.
