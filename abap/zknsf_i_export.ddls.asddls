@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: Export'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define view entity ZKNSF_I_EXPORT
  as select from    ZKNSF_I_ATC_FINDINGS     as fnd
    left outer join ZKNSF_I_FUNCTION_MODULES as functionModules on functionModules.functionModule = fnd.refObjectName
    left outer join ALL_CDS_STOB_VIEWS       as cds_stob        on cds_stob.DDLSourceName = fnd.refObjectName
    left outer join ALL_CDS_SQL_VIEWS        as cds_sql         on cds_sql.DDLSourceName = fnd.refObjectName

{
  key     cast( fnd.displayId  as zknsf_run_id)                       as runId,
  key     cast( fnd.itemId as zknsf_item_id preserving type )         as itemId,
          cast( fnd.objectType as zknsf_object_type )                 as objectType,
          cast( fnd.objectName as zknsf_object_name preserving type ) as objectName,
          cast( fnd.devClass as zknsf_dev_class )                     as devClass,
          cast( fnd.softwareComponent as zknsf_sw_comp )              as softwareComponent,
          cast( fnd.messageId as zknsf_message_id )                   as messageId,
          cast(  case fnd.refObjectType
          when 'STOB' then 'CDS_STOB'
          when 'DDLS' then
          case when cds_sql.SQLViewName is not null then 'CDS_SQL_VIEW'  else 'CDS_STOB' end
          else fnd.refObjectType end   as zknsf_ref_object_type  )    as refObjectType,
          cast( case when fnd.refObjectType = 'DDLS' and cds_sql.SQLViewName is not null then
          cds_sql.SQLViewName
          else  fnd.refObjectName end as zknsf_ref_object_name )      as refObjectName


}
where
          fnd.softwareComponent       != 'LOCAL'
  and(
    (
          fnd.messageId               =  '5'
      or  fnd.messageId               =  '2'
      or  fnd.messageId               =  'X'
    )
    or(
          fnd.refObjectName           is not initial
      and fnd.refObjectType           is not initial
      and fnd.refApplicationComponent is not initial
      and fnd.refSoftwareComponent    is not initial
    )
  );
