@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: Development Objects'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define view entity ZKNSF_I_DEVELOPMENT_OBJECTS
  as select from ZKNSF_I_SCORING as fnd

{
  key   fnd.runId                 as runId,
  key   fnd.objectType            as objectType,
  key   fnd.objectName            as objectName,
        fnd.devClass              as devClass,
        sum( fnd.score )          as score
}
group by
  fnd.runId,
  fnd.objectType,
  fnd.objectName,
  fnd.devClass;
