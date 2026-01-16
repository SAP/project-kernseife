using DevelopmentService as service from '../../srv/development-service';

annotate service.Exemptions with @(
    Capabilities: {FilterFunctions: ['tolower', ]},
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Value : applicantComment,
            Label : 'applicantComment',
        },
        {
            $Type : 'UI.DataField',
            Value : applicantReason,
            Label : 'applicantReason',
        },
        {
            $Type : 'UI.DataField',
            Value : applicantUserName,
            Label : 'applicantUserName',
        },
        {
            $Type : 'UI.DataField',
            Value : applicantUserId,
            Label : 'applicantUserId',
        },
        {
            $Type : 'UI.DataField',
            Value : applicantLastChangedAt,
            Label : 'applicantLastChangedAt',
        },
        {
            $Type : 'UI.DataField',
            Value : approverComment,
            Label : 'approverComment',
        },
        {
            $Type : 'UI.DataField',
            Value : approverLastChangedAt,
            Label : 'approverLastChangedAt',
        },
        {
            $Type : 'UI.DataField',
            Value : approverUserId,
            Label : 'approverUserId',
        },
        {
            $Type : 'UI.DataField',
            Value : checkClass,
            Label : 'checkClass',
        },
        {
            $Type : 'UI.DataField',
            Value : approverUserName,
            Label : 'approverUserName',
        },
        {
            $Type : 'UI.DataField',
            Value : checkScope,
            Label : 'checkScope',
        },
        {
            $Type : 'UI.DataField',
            Value : checksumValue,
            Label : 'checksumValue',
        },
        {
            $Type : 'UI.DataField',
            Value : checksumVersion,
            Label : 'checksumVersion',
        },
        {
            $Type : 'UI.DataField',
            Value : lastChangedAt,
            Label : 'lastChangedAt',
        },
        {
            $Type : 'UI.DataField',
            Value : messageId,
            Label : 'messageId',
        },
        {
            $Type : 'UI.DataField',
            Value : objectName,
            Label : 'objectName',
        },
        {
            $Type : 'UI.DataField',
            Value : objectScope,
            Label : 'objectScope',
        },
        {
            $Type : 'UI.DataField',
            Value : objectType,
            Label : 'objectType',
        },
        {
            $Type : 'UI.DataField',
            Value : subObjectName,
            Label : 'subObjectName',
        },
        {
            $Type : 'UI.DataField',
            Value : subObjectType,
            Label : 'subObjectType',
        },
        {
            $Type : 'UI.DataField',
            Value : validUntil,
            Label : 'validUntil',
        },
    ],
);