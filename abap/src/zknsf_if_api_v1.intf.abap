INTERFACE zknsf_if_api_v1
  PUBLIC .
  TYPES:
    BEGIN OF ty_rating,
      "! $required
      code        TYPE c LENGTH 3,
      "! $required
      title       TYPE string,
      "! $required
      criticality TYPE c LENGTH 1,
    END OF ty_rating .

  TYPES:
 ty_ratings TYPE STANDARD TABLE OF ty_rating WITH DEFAULT KEY .
  TYPES:
    BEGIN OF ty_main,
      "! $required
      format_version         TYPE if_aff_types_v1=>ty_format_version,
      ratings                TYPE ty_ratings,
      object_classifications TYPE STANDARD TABLE OF if_ycm_classic_api_list_v2=>ty_object_classification WITH DEFAULT KEY,
    END OF ty_main .
ENDINTERFACE.
