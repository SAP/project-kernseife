using DevelopmentService as service from '../../srv/development-service';

annotate service.Exemptions with @(UI.SelectionFields: [
    objectType,
    objectName,
    state_code,
    applicantUserId,
    approverUserId,
    validUntil,
    messageId,
    lastChangedAt,
    checkScope_code,
    objectScope_code,
    checkClass
]);

annotate service.Exemptions with {
    state_code
                           @Common.Label                   : '{i18n>state}'
                           @Common.Text                    : state.title
                           @Common.Text.@UI.TextArrangement: #TextOnly
                           @Common.ValueList               : {
        $Type         : 'Common.ValueListType',
        CollectionPath: 'ExemptionStates',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: state_code,
                ValueListProperty: 'code'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'title'
            }
        ],
        Label         : '{i18n>state}'
    }
                           @Common.ValueListWithFixedValues: true;
    objectType
                           @Common.Label                   : '{i18n>objectType}'
                           @Common.ValueList               : {
        $Type         : 'Common.ValueListType',
        CollectionPath: 'ExemptionObjectTypes',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: objectType,
                ValueListProperty: 'objectType'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'title'
            }
        ],
        Label         : '{i18n>chooseTadirObjectType}'
    }
                           @Common.ValueListWithFixedValues: true;
    objectName             @Common.Label: '{i18n>objectName}';
    objectScope_code       @Common.Label                   : '{i18n>objectScope}'
                           @Common.Text                    : objectScope.title
                           @Common.Text.@UI.TextArrangement: #TextOnly;
    checkScope_code        @Common.Label                   : '{i18n>checkScope}'
                           @Common.Text                    : checkScope.title
                           @Common.Text.@UI.TextArrangement: #TextOnly;
    applicantUserId        @Common.Label                   : '{i18n>applicantUserId}'
                           @Common.Text                    : applicantUserName
                           @Common.Text.@UI.TextArrangement: #TextFirst;
    applicantReason        @Common.Label: '{i18n>applicantReason}';
    applicantComment       @Common.Label: '{i18n>applicantComment}';
    approverUserId         @Common.Label                   : '{i18n>approverUserId}'
                           @Common.Text                    : approverUserName
                           @Common.Text.@UI.TextArrangement: #TextFirst;
    approverComment        @Common.Label: '{i18n>approverComment}';
    validUntil             @Common.Label: '{i18n>validUntil}';
    messageId              @Common.Label                   : '{i18n>messageId}'

                           @Common.Text                    : rating.title
                           @Common.Text.@UI.TextArrangement: #TextFirst;
    lastChangedAt          @Common.Label: '{i18n>lastChangedAt}';
    applicantLastChangedAt @Common.Label: '{i18n>applicantLastChangedAt}';
    approverLastChangedAt  @Common.Label: '{i18n>approverLastChangedAt}';
    checkClass             @Common.Label: '{i18n>checkClass}';
    checksumValue          @Common.Label: '{i18n>checksumValue}';
    checksumVersion        @Common.Label: '{i18n>checksumVersion}';
    subObjectName          @Common.Label: '{i18n>subObjectName}';
    subObjectType          @Common.Label: '{i18n>subObjectType}';
    applicantUserName      @Common.Label: '{i18n>applicantUserName}';
    approverUserName       @Common.Label: '{i18n>approverUserName}';
}

annotate service.Exemptions with @(
    Capabilities: {FilterFunctions: ['tolower',
    ]},
    UI.LineItem : [
        {
            $Type                : 'UI.DataField',
            Value                : objectType,
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : objectName,
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '15rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : messageId,
            ![@UI.Importance]        : #High,
            ![@HTML5.CssDefaults]    : {width: '12rem'},
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : rating.criticality.criticality,
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : state_code,
            ![@UI.Importance]        : #High,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : state.criticality.criticality,
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : objectScope_code,
            ![@UI.Importance]        : #Medium,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : objectScope.criticality.criticality,
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : checkScope_code,
            ![@UI.Importance]        : #Medium,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : checkScope.criticality.criticality,
        },
        {
            $Type                : 'UI.DataField',
            Value                : applicantUserId,
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '8rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : applicantReason,
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : applicantComment,
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '15rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : approverUserId,
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '8rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : approverComment,
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '15rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : validUntil,
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '8rem'},
        },
        {
            $Type            : 'UI.DataField',
            Value            : lastChangedAt,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Value            : applicantLastChangedAt,
            ![@UI.Importance]: #Low,
        },

        {
            $Type            : 'UI.DataField',
            Value            : approverLastChangedAt,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Value            : checkClass,
            ![@UI.Importance]: #Low,
        },

        {
            $Type            : 'UI.DataField',
            Value            : checksumValue,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Value            : checksumVersion,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Value            : subObjectName,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Value            : subObjectType,
            ![@UI.Importance]: #Low,
        },

        {
            $Type            : 'UI.DataField',
            Value            : applicantUserName,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Value            : approverUserName,
            ![@UI.Importance]: #Low,
        },
    ],
);
