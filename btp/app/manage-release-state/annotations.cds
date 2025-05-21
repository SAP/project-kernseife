using AdminService as service from '../../srv/admin-service';

annotate service.ReleaseStates with @Capabilities: {FilterFunctions: ['tolower', ]};

annotate service.ReleaseStates with @(
    UI.LineItem                           : [
        {
            $Type                : 'UI.DataField',
            Value                : tadirObjectType,
            Label                : '{i18n>tadirObjectType}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : tadirObjectName,
            Label                : '{i18n>tadirObjectName}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '12rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : objectType,
            Label                : '{i18n>objectType}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : objectName,
            Label                : '{i18n>objectKey}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '12rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : softwareComponent,
            Label                : '{i18n>softwareComponent}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '11rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : applicationComponent,
            Label                : '{i18n>applicationComponent}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '10rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : releaseLevel.title,
            Label                    : '{i18n>releaseLevel}',
            ![@UI.Importance]        : #High,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : releaseLevel.criticality.criticality,
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : releaseInfo_code,
            Label                    : '{i18n>releaseInfo}',
            ![@UI.Importance]        : #High,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : releaseInfo.criticality.criticality,
            ![@HTML5.CssDefaults]    : {width: '8.5rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : classicInfo_code,
            Label                    : '{i18n>classicInfo}',
            ![@UI.Importance]        : #High,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : classicInfo.criticality.criticality,
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : successorClassification_code,
            Label                    : '{i18n>successorClassification}',
            ![@UI.Importance]        : #High,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : successorClassification.criticality.criticality,
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : successorConceptName,
            Label                : '{i18n>successorConceptName}',
            ![@UI.Importance]    : #Low,
            ![@HTML5.CssDefaults]: {width: '6rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : successorList.objectName,
            Label                : '{i18n>successorObject}',
            ![@UI.Importance]    : #Low,
            ![@HTML5.CssDefaults]: {width: '12rem'},
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'AdminService.EntityContainer/loadReleaseState',
            Label : '{i18n>loadReleaseState}',
        },
         {
            $Type : 'UI.DataFieldForAction',
            Action: 'AdminService.EntityContainer/exportMissingClassification',
            Label : '{i18n>exportMissingClassification}',
        },

    ],
    UI.SelectionPresentationVariant #table: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem', ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
    UI.HeaderInfo                         : {
        TypeName      : '{i18n>releaseState}',
        TypeNamePlural: '{i18n>releaseStates}',
        Title         : {
            $Type: 'UI.DataField',
            Value: objectName,
        },
        Description   : {
            $Type: 'UI.DataField',
            Value: objectType,
        },
    },
    UI.HeaderFacets                       : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>generalInformation}',
            ID    : 'generalInformation',
            Target: '@UI.FieldGroup#generalInformation',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>release}',
            ID    : 'information',
            Target: '@UI.FieldGroup#information',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>successor}',
            ID    : 'successor',
            Target: '@UI.FieldGroup#successor',
        },
    ],
    UI.FieldGroup #generalInformation     : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: applicationComponent,
                Label: '{i18n>applicationComponent}',
            },
            {
                $Type: 'UI.DataField',
                Value: softwareComponent,
                Label: '{i18n>softwareComponent}',
            },
            {
                $Type: 'UI.DataField',
                Value: releaseLevel_code,
            },
        ],
    },
    UI.FieldGroup #information            : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type                    : 'UI.DataField',
                Value                    : releaseInfo_code,
                Criticality              : releaseInfo.criticality.criticality,
                CriticalityRepresentation: #WithoutIcon,
            },
            {
                $Type      : 'UI.DataField',
                Value      : classicInfo_code,
                Criticality: classicInfo.criticality.criticality,
            },
        ],
    },
    UI.FieldGroup #successor              : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: successorClassification.title,
                Label: '{i18n>successorClassification}',
            },
            {
                $Type: 'UI.DataField',
                Value: successorConceptName,
                Label: '{i18n>successorConceptName}',
            },
        ],
    },
);

annotate service.ReleaseStates with @(UI.Facets: [{
    $Type : 'UI.ReferenceFacet',
    Label : '{i18n>successorList}',
    ID    : 'successorList',
    Target: 'successorList/@UI.LineItem#successorList',
}, ]);

annotate service.ReleaseStateSuccessors with @(UI.LineItem #successorList: [
    {
        $Type            : 'UI.DataField',
        Value            : tadirObjectType,
        Label            : '{i18n>tadirObjectType}',
        ![@UI.Importance]: #Medium,
    },
    {
        $Type            : 'UI.DataField',
        Value            : tadirObjectName,
        Label            : '{i18n>tadirObjectName}',
        ![@UI.Importance]: #Medium,
    },
    {
        $Type            : 'UI.DataField',
        Value            : objectType,
        Label            : '{i18n>objectType}',
        ![@UI.Importance]: #High,
    },
    {
        $Type            : 'UI.DataField',
        Value            : objectName,
        Label            : '{i18n>objectName}',
        ![@UI.Importance]: #High,
    },
]);

annotate service.ReleaseStates with @(UI.SelectionFields: [
    objectName,
    objectType,
    releaseLevel_code,
    releaseInfo_code,
    classicInfo_code,
    successorClassification_code,
]);


annotate service.ReleaseStates with {
    objectType              @Common.Label: '{i18n>objectType}';
    objectName              @Common.Label: '{i18n>objectName}';
    releaseLevel            @Common.Label: '{i18n>releaseLevel}';
    releaseInfo             @(
        Common.Label: '{i18n>releaseInfo}',
        Common.Text : {
            $value                : releaseInfo.title,
            ![@UI.TextArrangement]: #TextOnly
        },
    );
    classicInfo             @(
        Common.Label: '{i18n>classicInfo}',
        Common.Text : {
            $value                : classicInfo.title,
            ![@UI.TextArrangement]: #TextOnly
        },
    );
    successorClassification @(
        Common.Label: '{i18n>successorClassification}',
        Common.Text : {
            $value                : successorClassification.title,
            ![@UI.TextArrangement]: #TextOnly
        },
    );
};
