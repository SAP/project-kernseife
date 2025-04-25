
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: Function Modules'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define view entity ZKNSF_I_FUNCTION_MODULES
  as select from    enlfdir as fdir
    join            tadir   as tadir on  tadir.object   = 'FUGR'
                                     and tadir.obj_name = fdir.area
{
  tadir.obj_name as functionGroup,
  fdir.funcname  as functionModule
}
