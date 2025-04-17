@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: ATC Check Findings'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #MIXED
}
@AbapCatalog.viewEnhancementCategory: [#NONE]
define view entity ZKNSF_I_ATC_FINDINGS
  as select from    satc_ac_resulth      as h
    inner join      satc_ac_fnd_v        as fnd_v                on h.check_run_ix = fnd_v.check_run_ix
    inner join      satc_ac_itm          as itm                  on itm.item_id = fnd_v.item_id   // item
    inner join      satc_ac_fnd          as fnd                  on fnd.item_id = fnd_v.item_id   // finding
    inner join      satc_ac_obj          as obj                  on obj.object_ix = fnd.object_ix // object
    inner join      satc_ac_osy          as osy // package and contact person
                                                                 on  osy.object_ix = fnd.object_ix
                                                                 and osy.system_ix = fnd.system_ix
    inner join      satc_ac_chm          as chm                  on chm.module_ix = fnd.module_ix   // check module id
    inner join      satc_ac_cmm          as cmm                  on  cmm.module_ix  = fnd.module_ix // check module id
                                                                 and cmm.message_ix = fnd.message_ix
    inner join      satc_ac_chc          as chc                  on chc.check_conf_ix = fnd.check_conf_ix // check variant

    left outer join satc_ac_msgt         as checkTitle           on  checkTitle.module_ix  = fnd.module_ix
                                                                 and checkTitle.message_ix = 0
                                                                 and checkTitle.langu      = $session.system_language
    left outer join satc_ac_msgt         as checkMsg             on  checkMsg.module_ix  = fnd.module_ix
                                                                 and checkMsg.message_ix = fnd.message_ix
                                                                 and checkMsg.langu      = $session.system_language
                                                                 


    left outer join SATC_AC_ATT_VAL_DDLV as refObjType           on  refObjType.item_id = fnd.item_id
                                                                 and refObjType.name    = 'REF_OBJ_TYPE'

    left outer join SATC_AC_ATT_VAL_DDLV as refObjName           on  refObjName.item_id = fnd.item_id
                                                                 and refObjName.name    = 'REF_OBJ_NAME'
                                                                

    left outer join SATC_AC_ATT_VAL_DDLV as sItemState           on  sItemState.item_id = fnd.item_id
                                                                 and sItemState.name    = 'SITEM_STATE'

    left outer join SATC_AC_ATT_VAL_DDLV as refApplComponent     on  refApplComponent.item_id = fnd.item_id
                                                                 and refApplComponent.name    = 'APPLICATION_COMPONENT'

    left outer join SATC_AC_ATT_VAL_DDLV as refSoftwareComponent on  refSoftwareComponent.item_id = fnd.item_id
                                                                 and refSoftwareComponent.name    = 'REF_SOFTWARE_COMPONENT'

    left outer join SATC_AC_ATT_VAL_DDLV as refDevClass          on  refDevClass.item_id = fnd.item_id
                                                                 and refDevClass.name    = 'REF_PACKAGE'


    left outer join SATC_AC_ATT_VAL_DDLV as sNote                on  sNote.item_id = fnd.item_id
                                                                 and sNote.name    = 'NOTE'

    left outer join SATC_AC_ATT_VAL_DDLV as addInfo              on  addInfo.item_id = fnd.item_id
                                                                 and addInfo.name    = 'ADD_INFO'
    left outer join dd02l                as dd02l                on  dd02l.tabname  = obj.obj_name
                                                                 and dd02l.as4local = 'A'
    left outer join dd02l                as dd02l_ref            on  dd02l_ref.tabname  = refObjName.value
                                                                 and dd02l_ref.as4local = 'A'
{
  key fnd_v.item_id              as itemId,
  key h.display_id               as displayId,

      itm.created_on             as createdAt,
      itm.status                 as status,

      obj.obj_name               as objectName,
      obj.obj_type               as objectType,
      case obj.obj_type
      when 'TABL' then
           dd02l.tabclass
      else
           obj.obj_type
      end                        as subType,

      osy.package_name           as devClass,
      osy.contact_person         as contactPerson,

      osy.dlv_release            as sapRelease,
      osy.dlv_unit               as softwareComponent,
      osy.tr_layer               as transportLayer,

      itm.processor              as responsible,

      chc.check_variant          as checkVariant,

      chm.module_id              as moduleId,
      chm.ci_id                  as checkClass,
      cmm.message_id             as messageId,
      cmm.quality_standard       as qualityStandard,

      fnd_v.exc_kind             as excemptionKind,
      fnd_v.exc_validity         as excemptionValidity,
      fnd_v.exc_approval         as excemptionApproval,

      fnd.exc_kind               as excemptionKindItem,
      fnd.exc_validity           as excemptionValidityItem,
      fnd.exc_approval           as excemptionApprovalItem,
      fnd.has_quickfixes         as hasQuickfixes,

      checkTitle.title           as checkTitle,
      checkMsg.title             as checkMessage,
      
      

      refObjType.value           as refObjectType,
      refObjName.value           as refObjectName,
      case refObjType.value
      when 'TABL' then
        dd02l_ref.tabclass
      else
        refObjType.value
      end                        as refSubType,

      refApplComponent.value     as refApplicationComponent,
      refSoftwareComponent.value as refSoftwareComponent,
      refDevClass.value          as refDevClass,

      sItemState.value           as simplificationItemState,
      sNote.value                as simplificationNote,
      addInfo.value              as additionalInfo,

      fnd_v.last_changed_by      as lastChangedBy,
      fnd_v.last_changed_on      as lastCangedOn,
      fnd_v.priority             as priority,
      fnd_v.created_on           as timestamp,
      fnd_v.host                 as host,
      fnd_v.status_new           as statusNew,
      fnd_v.status_old           as statusOld,
      fnd_v.sub_index            as subIndex
}
