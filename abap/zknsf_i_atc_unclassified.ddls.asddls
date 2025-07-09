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
    left outer join ALL_CDS_STOB_VIEWS       as cds_stob        on cds_stob.DDLSourceName = fnd.refObjectName
    left outer join ALL_CDS_SQL_VIEWS        as cds_sql         on cds_sql.DDLSourceName = fnd.refObjectName
{
  key     cast(  case fnd.refObjectType
   when 'STOB' then 'CDS_STOB'
   when 'DDLS' then
   case when cds_sql.SQLViewName is not null then 'CDS_SQL_VIEW'  else 'CDS_STOB' end
   else fnd.refObjectType end   as zknsf_object_type  )         as objectType,
  key     cast( case when fnd.refObjectType = 'DDLS' and cds_sql.SQLViewName is not null then
      cds_sql.SQLViewName
   else  fnd.refObjectName end as zknsf_object_name )           as objectName,
  key     cast( fnd.refApplicationComponent as zknsf_app_comp ) as applicationComponent,
          cast(
          case fnd.refSubType
            when 'STOB' then 'CDS_STOB'
            when 'DDLS' then
                case when cds_sql.SQLViewName is not null then 'CDS_SQL_VIEW'
                else 'CDS_STOB' end
            else fnd.refSubType end   as zknsf_sub_type)        as subType,
          cast( fnd.refSoftwareComponent    as zknsf_sw_comp )  as softwareComponent,
          cast(case fnd.refObjectType
          when 'FUNC' then
            'FUGR'
          when 'STOB' then
            'DDLS'
          else
            fnd.refObjectType
          end      as zknsf_tadir_object_type )                 as tadirObjectType,
          cast( case fnd.refObjectType
          when 'FUNC' then
           functionModules.functionGroup
          when 'STOB' then
            cds_stob.DDLSourceName
          else
           fnd.refObjectName
          end        as zknsf_tadir_object_name )               as tadirObjectName
}
where
      fnd.messageId               = 'NOC'
  and fnd.refObjectName           is not initial
  and fnd.refObjectType           is not initial
  and fnd.refApplicationComponent is not initial
  and fnd.refSoftwareComponent    is not initial
  and fnd.timestamp               > dats_tims_to_tstmp(tstmp_to_dats( tstmp_add_seconds(tstmp_current_utctimestamp(),cast(-86400 as abap.dec(15,0)), 'NULL'),
  
                                    abap_system_timezone( $session.client,'NULL' ),
                                    $session.client,
                                    'NULL' ),
                                        tstmp_to_tims( tstmp_current_utctimestamp(),
                                    abap_system_timezone( $session.client,'NULL' ),
                                    $session.client,
                                    'NULL' ),
                                    abap_system_timezone( $session.client,'NULL' ),
                                    $session.client,
                                   'NULL' )
group by
  fnd.refSubType,
  fnd.refApplicationComponent,
  fnd.refSoftwareComponent,
  fnd.refObjectType,
  fnd.refObjectName,
  cds_stob.DDLSourceName,
  cds_stob.CDSName,
  cds_sql.DDLSourceName,
  cds_sql.SQLViewName,
  functionModules.functionGroup
