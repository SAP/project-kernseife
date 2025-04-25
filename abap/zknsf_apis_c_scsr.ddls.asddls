@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Kernseife: APIs with successors'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define view entity ZKNSF_APIS_C_SCSR 
  as select from    zknsf_api_cache as api
    left outer join zknsf_api_scsr  as scsr  on api.api_id = scsr.api_id
    left outer join zknsf_api_label as label on api.api_id = label.api_id
  association to zknsf_api_header as header on api.file_id = header.file_id
{
  key api.api_id,
  key api.file_id,
  key api.tadir_object,
  key api.tadir_obj_name,
      api.object_type,
      api.object_key,
      api.software_component,
      api.application_component,
      api.state,
      scsr.successor_tadir_object,
      scsr.successor_tadir_obj_name,
      scsr.successor_object_type,
      scsr.successor_object_key,
      label.label_name
}
where
      header.data_type = 'K'
