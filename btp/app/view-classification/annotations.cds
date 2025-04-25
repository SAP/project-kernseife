using ViewerService as service from '../../srv/viewer-service';

annotate service.Classifications with @Capabilities: {FilterFunctions: ['tolower', ]};

annotate service.Classifications with @(UI.LineItem: [
    {
        $Type                  : 'UI.DataField',
        Value                  : applicationComponent,
        Label                  : '{i18n>applicationComponent}',
        ![@UI.Importance]      : #Low,
        ![@Common.FieldControl]: #ReadOnly,
        ![@HTML5.CssDefaults]  : {width: '10rem'},
    },
    {
        $Type                : 'UI.DataField',
        Value                : subType,
        Label                : '{i18n>objectType}',
        ![@UI.Importance]    : #Medium,
        ![@HTML5.CssDefaults]: {width: '4rem'},
    },
    {
        $Type                : 'UI.DataField',
        Value                : objectName,
        Label                : '{i18n>objectName}',
        ![@UI.Importance]    : #High,
        ![@HTML5.CssDefaults]: {width: '15rem'},
    },
    {
        $Type                : 'UI.DataField',
        Value                : softwareComponent,
        Label                : '{i18n>softwareComponent}',
        ![@UI.Importance]    : #Medium,
        ![@HTML5.CssDefaults]: {width: '11rem'},
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : rating_code,
        Label                    : '{i18n>ratingCode}',
        ![@UI.Importance]        : #High,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : rating.criticality.criticality,
        ![@HTML5.CssDefaults]    : {width: '7rem'},
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : rating.score,
        Label                    : '{i18n>score}',
        Criticality              : rating.criticality.criticality,
        CriticalityRepresentation: #WithoutIcon,
        ![@UI.Importance]        : #Low,
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : releaseLevel_code,
        Label                    : '{i18n>releaseLevel}',
        ![@UI.Importance]        : #High,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : releaseLevel.criticality.criticality,
        ![@HTML5.CssDefaults]    : {width: '8.5rem'},
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : releaseState.releaseInfo.title,
        Label                    : '{i18n>releaseInfo}',
        ![@UI.Importance]        : #Low,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : releaseState.releaseInfo.criticality.criticality,
        ![@HTML5.CssDefaults]    : {width: '7rem'},
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : releaseState.classicInfo.title,
        Label                    : '{i18n>classicInfo}',
        ![@UI.Importance]        : #Low,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : releaseState.classicInfo.criticality.criticality,
        ![@HTML5.CssDefaults]    : {width: '7rem'},
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : successorClassification_code,
        Label                    : '{i18n>successorClassification}',
        ![@UI.Importance]        : #Medium,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : successorClassification.criticality.criticality,
        ![@HTML5.CssDefaults]    : {width: '6rem'},
    },
    {
        $Type                : 'UI.DataField',
        Value                : comment,
        Label                : '{i18n>comment}',
        ![@UI.Importance]    : #Medium,
        ![@HTML5.CssDefaults]: {width: 'auto'},
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : adoptionEffort_code,
        Label                    : '{i18n>adoptionEffort}',
        ![@UI.Importance]        : #Low,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : adoptionEffort.criticality.criticality,
        ![@HTML5.CssDefaults]    : {width: '4rem'},
    },
    {
        $Type                : 'UI.DataField',
        Value                : successorList.objectName,
        Label                : '{i18n>successorObject}',
        ![@UI.Importance]    : #Low,
        ![@HTML5.CssDefaults]: {width: '12rem'},
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : totalScore,
        Label                    : '{i18n>totalScore}',
        ![@UI.Importance]        : #Medium,
        ![@Common.FieldControl]  : #ReadOnly,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : {$edmJson: {$If: [
            {$Lt: [
                {$Path: 'totalScore'},
                100
            ]},
            0,
            {$If: [
                {$Gt: [
                    {$Path: 'totalScore'},
                    1000
                ]},
                1,
                2
            ]}
        ]}}
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : referenceCount,
        Label                    : '{i18n>referenceCount}',
        ![@UI.Importance]        : #Medium,
        ![@Common.FieldControl]  : #ReadOnly,
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : {$edmJson: {$If: [
            {$Lt: [
                {$Path: 'referenceCount'},
                10
            ]},
            0,
            {$If: [
                {$Gt: [
                    {$Path: 'referenceCount'},
                    100
                ]},
                1,
                2
            ]}
        ]}}
    },
    {
        $Type: 'UI.DataField',
        Value: noteList.note,
        Label: '{i18n>notes}',
    },
    {
        $Type: 'UI.DataField',
        Value: numberOfSimplificationNotes,
    },
    {
        $Type            : 'UI.DataField',
        Value            : createdAt,
        Label            : '{i18n>createdAt}',
        ![@UI.Importance]: #Low,
    },
    {
        $Type            : 'UI.DataField',
        Value            : createdBy,
        Label            : '{i18n>createdAt}',
        ![@UI.Importance]: #Low,
    },
    {
        $Type            : 'UI.DataField',
        Value            : modifiedAt,
        Label            : '{i18n>modifiedAt}',
        ![@UI.Importance]: #Low,
    },
    {
        $Type            : 'UI.DataField',
        Value            : modifiedBy,
        Label            : '{i18n>modifiedBy}',
        ![@UI.Importance]: #Low,
    }
]);

annotate service.Classifications with @(UI.Facets: [
    {
        $Type : 'UI.ReferenceFacet',
        Label : '{i18n>successorList}',
        ID    : 'successorList',
        Target: 'successorList/@UI.LineItem#SuccessorList',
    },
    {
        $Type : 'UI.ReferenceFacet',
        Label : '{i18n>noteList}',
        ID    : 'noteList',
        Target: 'noteList/@UI.LineItem#NoteList',
    },
    {
        $Type : 'UI.ReferenceFacet',
        Label : '{i18n>developmentObjectList}',
        ID    : 'developmentObjectList',
        Target: 'developmentObjectList/@UI.LineItem#developmentObjectList',
    },
    {
        $Type : 'UI.ReferenceFacet',
        Label : '{i18n>codeSnippets}',
        ID    : 'codeSnippets',
        Target: 'codeSnippets/@UI.LineItem#codeSnippets',
    },
]);


annotate service.DevelopmentObjectsAggregated with @(
    UI.LineItem #developmentObjectList          : [
        {
            $Type                : 'UI.DataField',
            Value                : objectName,
            Label                : '{i18n>objectName}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '18rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : objectType,
            Label                : '{i18n>objectType}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : code,
            Label                    : '{i18n>rating}',
            Criticality              : criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #High,
            ![@HTML5.CssDefaults]    : {width: '16rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : score,
            Label                    : '{i18n>score}',
            Criticality              : criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #Medium,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : count,
            Label                : '{i18n>count}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : total,
            Label                : '{i18n>total}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '6rem'},
        },
        {
            $Type                : 'UI.DataFieldForAnnotation',
            Target               : '@UI.DataPoint#totalPercentage',
            Label                : '{i18n>totalPercentage}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '6rem'},

        },
    ],
    UI.SelectionPresentationVariant #findingList: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem#developmentObjectList', ],
            SortOrder     : [{
                $Type     : 'Common.SortOrderType',
                Property  : total,
                Descending: true,
            }, ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
    UI.DataPoint #totalPercentage               : {
        Value        : totalPercentage,
        Visualization: #Progress,
        TargetValue  : 100,
    },
);

annotate service.ClassificationSuccessors with @(UI.LineItem #SuccessorList: [
    {
        $Type: 'UI.DataField',
        Value: objectType,
        Label: '{i18n>objectType}',
    },
    {
        $Type: 'UI.DataField',
        Value: objectName,
        Label: '{i18n>objectName}',
    }
]);

annotate service.Classifications with @(
    UI.HeaderFacets                  : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>generalInformation}',
            ID    : 'GeneralInformation',
            Target: '@UI.FieldGroup#GeneralInformation',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Score',
            ID    : 'Score',
            Target: '@UI.FieldGroup#Score',
        },
    ],
    UI.FieldGroup #GeneralInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {

                $Type                  : 'UI.DataField',
                Value                  : applicationComponent,
                Label                  : '{i18n>applicationComponent}',
                ![@Common.FieldControl]: #ReadOnly
            },
            {

                $Type                  : 'UI.DataField',
                Value                  : softwareComponent,
                Label                  : '{i18n>softwareComponent}',
                ![@Common.FieldControl]: #ReadOnly,
            },
            {
                $Type                    : 'UI.DataField',
                Value                    : releaseLevel_code,
                Label                    : '{i18n>releaseLevel}',
                ![@Common.FieldControl]  : #ReadOnly,
                CriticalityRepresentation: #WithoutIcon,
                Criticality              : releaseLevel.criticality.criticality,
            },
            {
                $Type                    : 'UI.DataField',
                Value                    : successorClassification_code,
                Label                    : '{i18n>successorClassification}',
                CriticalityRepresentation: #WithoutIcon,
                Criticality              : successorClassification.criticality.criticality,
            }
        ],
    }
);

annotate service.Classifications with @(UI.FieldGroup #Score: {
    $Type: 'UI.FieldGroupType',
    Data : [
        {
            $Type                    : 'UI.DataField',
            Value                    : rating_code,
            Label                    : '{i18n>rating}',
            ![@Common.FieldControl]  : #Mandatory,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : rating.criticality.criticality,
        },
        {
            $Type: 'UI.DataField',
            Value: adoptionEffort_code,
            Label: '{i18n>adoptionEffort}',
        },
        {
            $Type: 'UI.DataField',
            Value: comment,
            Label: '{i18n>comment}',
        },
    ],
});


annotate service.Classifications with @(UI.HeaderInfo: {
    Title         : {
        $Type: 'UI.DataField',
        Value: '{subType} - {objectName}'
    },
    TypeName      : '{i18n>classification}',
    TypeNamePlural: '{i18n>classifications}',
    Description   : {
        $Type: 'UI.DataField',
        Value: applicationComponent,
    },
});

annotate service.Classifications with @(UI.SelectionFields: [
    subType,
    objectName,
    softwareComponent,
    applicationComponent,
    releaseLevel_code,
    successorClassification_code,
    rating_code,
    numberOfSimplificationNotes,
    totalScore,
]);

annotate service.Classifications with {
    successorClassification @Common.Label: '{i18n>successorClassification}';
    objectName              @Common.Label: '{i18n>objectName}';
    subType                 @Common.Label: '{i18n>objectType}';
};


annotate service.Classifications with @(UI.DataPoint #ratingScore: {
    Value               : rating.score,
    Visualization       : #Progress,
    TargetValue         : 10,
    ![@Common.QuickInfo]: rating.code,
    Criticality         : rating.criticality.criticality
}, );

annotate service.Classifications with @(UI.SelectionPresentationVariant #table: {
    $Type              : 'UI.SelectionPresentationVariantType',
    PresentationVariant: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.LineItem', ],
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : totalScore,
            Descending: true,
        }, ],
    },
    SelectionVariant   : {
        $Type        : 'UI.SelectionVariantType',
        SelectOptions: [],
    },
});

annotate service.Classifications with {
    @Common.Text: {
        $value                : rating.title,
        ![@UI.TextArrangement]: #TextOnly,
    } rating;
    @Common.Text: {
        $value                : releaseLevel.title,
        ![@UI.TextArrangement]: #TextOnly,
    } releaseLevel;
    @Common.Text: {
        $value                : successorClassification.title,
        ![@UI.TextArrangement]: #TextOnly,
    } successorClassification;
};

annotate service.Notes with @(UI.LineItem #NoteList: [
    {
        $Type: 'UI.DataFieldWithUrl',
        Value: note,
        Url  : 'https://me.sap.com/notes/{note}',
        Label: '{i18n>note}',
    },
    {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
    {
        $Type                    : 'UI.DataField',
        Value                    : noteClassification_code,
        Label                    : '{i18n>noteClassification}',
        Criticality              : noteClassification.criticality.criticality,
        CriticalityRepresentation: #WithoutIcon,
    },
]);

annotate service.NoteClassifications with {
    code @Common.Text: {
        $value                : title,
        ![@UI.TextArrangement]: #TextFirst
    }
};

annotate service.CodeSnippets with @(
    UI.LineItem #codeSnippets        : [
        {
            $Type: 'UI.DataField',
            Value: title,
            Label: '{i18n>title}',
        },
        {
            $Type: 'UI.DataField',
            Value: comment,
            Label: '{i18n>comment}',
        },
    ],
    UI.HeaderInfo                    : {
        TypeName      : '{i18n>codeSnippet}',
        TypeNamePlural: '{i18n>codeSnippets}',
    },
    UI.HeaderFacets                  : [{
        $Type : 'UI.ReferenceFacet',
        Label : '{i18n>generalInformation}',
        ID    : 'generalInformation',
        Target: '@UI.FieldGroup#generalInformation',
    }, ],
    UI.FieldGroup #generalInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: title,
                Label: '{i18n>title}',
            },
            {
                $Type: 'UI.DataField',
                Value: comment,
                Label: '{i18n>comment}',
            },
        ],
    },
);

annotate service.DevelopmentObjectsAggregated with {
    objectName @Common.SemanticObject: 'DevelopmentObjects'
};
