@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: User Exits'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define  view entity zknsf_i_user_exits as select from modattr as projects
inner join modact as active on active.name = projects.name
inner join modsap as FunctionModules on FunctionModules.name = active.member
inner join tfdir as Report on FunctionModules.member = Report.funcname


{

key projects.name as Project,
key active.member as UserExitName,
key FunctionModules.member as FMName,
FunctionModules.typ as FMType,
Report.pname as Report,
Report.include as IncludeNo,
Report.pname_main as MainReport,

substring(Report.pname, 5, length(Report.pname) ) as Namespace,
concat('Z', concat ( substring(Report.pname, 5, length(Report.pname) ), concat('U', Report.include ) )) as Include

}
where projects.status = 'A' and
 active.member <> ''
