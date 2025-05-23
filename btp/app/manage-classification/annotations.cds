using AdminService as service from '../../srv/admin-service';
using from '../../db/data-model';


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
        Value                : frameworkUsageList.framework.title,
        Label                : '{i18n>framework}',
        ![@UI.Importance]    : #Medium,
        ![@HTML5.CssDefaults]: {width: '6rem'},
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
        Label            : '{i18n>createdBy}',
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
    },
    {
        $Type : 'UI.DataFieldForAction',
        Action: 'AdminService.assignFramework',
        Label : '{i18n>assignFramework}',

    },
    {
        $Type : 'UI.DataFieldForAction',
        Action: 'AdminService.assignSuccessor',
        Label : '{i18n>assignSuccessor}',

    },
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
        Label : '{i18n>frameworks}',
        ID    : 'frameworksUsed',
        Target: 'frameworkUsageList/@UI.LineItem#frameworksUsed',
    },
    {
        $Type : 'UI.ReferenceFacet',
        Label : '{i18n>noteList}',
        ID    : 'noteList',
        Target: 'noteList/@UI.LineItem#NoteList',
    },
    {
        $Type : 'UI.ReferenceFacet',
        Label : '{i18n>codeSnippets}',
        ID    : 'codeSnippets',
        Target: 'codeSnippets/@UI.LineItem#codeSnippets',
    },
]);

annotate service.ClassificationSuccessors with @(UI.LineItem #SuccessorList: [
    {
        $Type                : 'UI.DataField',
        Value                : successorType_code,
        Label                : '{i18n>successorType}',
        ![@UI.Importance]    : #High,
        ![@HTML5.CssDefaults]: {width: '8rem'},
    },
    {
        $Type                : 'UI.DataField',
        Value                : tadirObjectType,
        Label                : '{i18n>tadirObjectType}',
        ![@UI.Importance]    : #High,
        ![@HTML5.CssDefaults]: {width: '4rem'},
    },
    {
        $Type                : 'UI.DataField',
        Value                : tadirObjectName,
        Label                : '{i18n>tadirObjectName}',
        ![@UI.Importance]    : #High,
        ![@HTML5.CssDefaults]: {width: '15rem'},
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
        Label                : '{i18n>objectName}',
        ![@UI.Importance]    : #High,
        ![@HTML5.CssDefaults]: {width: '15rem'},
    },
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
            Label                    : '{i18n>ratingCode}',
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
    createdBy,
    modifiedBy
]);

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
        Visualizations: ['@UI.LineItem',
        ],
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

annotate service.Classifications with {
    successorClassification @Common.Label: '{i18n>successorClassification}';
    objectName              @Common.Label: '{i18n>objectName}';
    subType                 @Common.Label: '{i18n>objectType}';
    comment                 @Common.Label: '{i18n>comment}';
    modifiedBy              @Common.Label: '{i18n>modifiedBy}';
    createdBy               @Common.Label: '{i18n>createdBy}';
    referenceCount          @Common.Label: '{i18n>referenceCount}';
    tadirObjectName         @Common.Label: '{i18n>tadirObjectName}';
    tadirObjectType         @Common.Label: '{i18n>tadirObjectType}';
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

annotate service.FrameworkUsages with @(UI.LineItem #frameworksUsed: [
    {
        $Type                    : 'UI.DataField',
        Value                    : framework_code,
        Label                    : '{i18n>code}',
        Criticality              : framework.criticality.criticality,
        CriticalityRepresentation: #WithoutIcon,
        ![@Common.FieldControl]  : #Mandatory,
    },
    {
        $Type                  : 'UI.DataField',
        Value                  : framework.title,
        Label                  : '{i18n>title}',
        ![@Common.FieldControl]: #ReadOnly,
    },
]);

annotate service.inFramework {
    code @(
        Common.Label                   : '{i18n>framework}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Frameworks',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ],
            Label         : '{i18n>chooseFramework}'
        },
        Common.ValueListWithFixedValues: true
    );
};

annotate service.inSuccessor {
    tadirObjectType @(
        Common.Label                   : '{i18n>tadirObjectType}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'ObjectTypes',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: tadirObjectType,
                    ValueListProperty: 'objectType'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ],
            Label         : '{i18n>chooseTadirObjectType}'
        },
        Common.ValueListWithFixedValues: true
    );
    objectType      @(
        Common.Label                   : '{i18n>objectType}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'ObjectTypeValueList',
            Parameters    : [{
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: objectType,
                ValueListProperty: 'objectType'
            }],
            Label         : '{i18n>chooseObjectType}'
        },
        Common.ValueListWithFixedValues: true
    );

    successorType   @(
        Common.Label                   : '{i18n>successorType}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'SuccessorTypes',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: successorType,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ],
            Label         : '{i18n>chooseSuccessorType}'
        },
        Common.ValueListWithFixedValues: true
    );
};
