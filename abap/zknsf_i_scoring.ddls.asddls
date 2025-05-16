@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: Scoring Findings'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define view entity ZKNSF_I_SCORING
  as select from ZKNSF_I_ATC_FINDINGS as fnd
    inner join   ZKNSF_I_RATINGS      as rating on rating.code = left(
      fnd.messageId, 3
    ) // As some findings use _SUC as appendix
  //  inner join satc_ac_resulth as h on h.display_id = fnd.displayId
  //  and h.run_series_name = 'ZKNSF_SCORING'

{
  key    cast( fnd.displayId  as zknsf_run_id)                       as runId,
  key    cast( fnd.itemId as zknsf_item_id preserving type )         as itemId,
  key    cast( fnd.objectType as zknsf_object_type )                 as objectType,
  key    cast( fnd.objectName as zknsf_object_name preserving type ) as objectName,
  key    cast( fnd.refObjectType as zknsf_ref_object_type )          as refObjectType,
  key    cast( fnd.refObjectName as zknsf_ref_object_name )          as refObjectName,
         cast( fnd.devClass as zknsf_dev_class )                     as devClass,
         cast( rating.code as zknsf_rating_code )                    as ratingCode,
         cast( rating.score as zknsf_rating_score)                   as score
}
where
      fnd.messageId               != 'NOC'
  and fnd.refObjectName           is not initial
  and fnd.refObjectType           is not initial
  and fnd.refApplicationComponent is not initial
  and fnd.refSoftwareComponent    is not initial;
