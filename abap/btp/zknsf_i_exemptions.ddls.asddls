@AccessControl.authorizationCheck: #MANDATORY
@EndUserText.label: 'Kernseife: Exemptions'
define view entity ZKNSF_I_EXEMPTIONS
  as select from satc_ci_exempt as exemp
  association [0..*] to satc_ci_reasonst as reasonText on exemp.reason = reasonText.reason_code
{
  key exemp.exemption_id             as exemptionId,
      exemp.state                    as state_code,
      exemp.chkclass                 as checkClass,
      exemp.object_scope             as objectScope_code,
      exemp.check_scope              as checkScope_code,
      exemp.chkcode                  as messageId,
      exemp.objname                  as objectName,
      exemp.objtype                  as objectType,
      exemp.subobjname               as subObjectName,
      exemp.subobjtype               as subObjectType,
      exemp.checksum_version         as checksumVersion,
      exemp.checksum                 as checksumValue,
      exemp.valid_until              as validUntil,
      exemp.applicant                as applicantUserId,
      @ObjectModel.readOnly: true
      @ObjectModel.virtualElement
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZKNSF_CL_EXEMPTIONS_SADL'
      cast( '' as abap.char( 80 )  ) as applicantUserName,
      exemp.appl_last                as applicantLastChangedAt,
      exemp.reason                   as applicantReason,
      reasonText[ langu = $session.system_language ].text                as applicantReasonText,
      exemp.appl_comment             as applicantComment,
      exemp.approver                 as approverUserId,
      @ObjectModel.readOnly: true
      @ObjectModel.virtualElement
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZKNSF_CL_EXEMPTIONS_SADL'
      cast( '' as abap.char( 80 )  ) as approverUserName,
      exemp.appr_last                as approverLastChangedAt,
      exemp.appr_comment             as approverComment,
      exemp.last_changed             as lastChangedAt,
      exemp.exemption_crc            as exemptionChecksum
}
where
  deleted <> 'X';
