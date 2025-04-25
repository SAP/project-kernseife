@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: Missing Classifications'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define view entity ZKNSF_I_ATC_UNCLASSIFIED
  as select from    ZKNSF_I_ATC_FINDINGS     as fnd
    left outer join ZKNSF_I_FUNCTION_MODULES as functionModules on functionModules.functionModule = fnd.refObjectName

{
  key     cast(  case fnd.refObjectType when 'STOB' then 'CDS_STOB'  else fnd.refObjectType end   as zknsf_object_type  ) as objectType,
  key     cast( fnd.refObjectName as zknsf_object_name )                                                              as objectName,
  key     cast( fnd.refApplicationComponent     as zknsf_app_comp )                                                   as applicationComponent,
          cast( fnd.refSubType   as zknsf_sub_type)                                                                   as subType,
          cast( fnd.refSoftwareComponent    as zknsf_sw_comp )                                                        as softwareComponent,
          cast(case fnd.refObjectType
          when 'FUNC' then
            'FUGR'
          when 'STOB' then
            'DDLS'
          else
            fnd.refObjectType
          end      as zknsf_tadir_object_type )                                                                       as tadirObjectType,
          cast( case fnd.refObjectType
          when 'FUNC' then
           functionModules.functionGroup
          else
           fnd.refObjectName
          end        as zknsf_tadir_object_name )                                                                     as tadirObjectName
}
where
  fnd.messageId = 'NOC' and
  fnd.refObjectName is not initial and
  fnd.refObjectType is not initial and
  fnd.refApplicationComponent is not initial and
  fnd.refSoftwareComponent is not initial 
group by
  fnd.refSubType,
  fnd.refApplicationComponent,
  fnd.refSoftwareComponent,
  fnd.refObjectType,
  fnd.refObjectName,
  functionModules.functionGroup
