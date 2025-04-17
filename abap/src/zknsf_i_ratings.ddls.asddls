@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: Ratings'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define view entity ZKNSF_I_RATINGS
  as select from    zknsf_ratings
{
  key code,
  title,
  criticality
}
