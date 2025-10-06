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
  as select from     ZKNSF_I_ATC_FINDINGS as fnd
    right outer join ZKNSF_I_SCORING      as score on  fnd.displayId  = score.runId
                                                   and fnd.objectType = score.objectType
                                                   and fnd.objectName = score.objectName

{
  key   fnd.displayId                                                                                                                          as runId,
  key   fnd.objectType                                                                                                                         as objectType,
  key   fnd.objectName                                                                                                                         as objectName,
        fnd.devClass                                                                                                                           as devClass,
        fnd.messageId                                                                                                                          as languageVersion,
        sum( score.score )                                                                                                                     as cleanCoreScore,
        case max( score.cleanCoreLevel ) when 'A' then case fnd.messageId when '5' then 'A' else 'B' end else max( score.cleanCoreLevel )  end as cleanCoreLevel
}
where
     fnd.messageId = '5'
  or fnd.messageId = '2'
  or fnd.messageId = 'X'
group by
  fnd.displayId,
  fnd.objectType,
  fnd.objectName,
  fnd.devClass,
  fnd.messageId;
