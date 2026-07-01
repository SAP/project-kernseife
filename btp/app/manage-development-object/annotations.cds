using DevelopmentService as service from '../../srv/development-service';

annotate service.DevelopmentObjects with @(
    Capabilities          : {FilterFunctions: ['tolower',
    ]},
    UI.Identification     : [
                             // {
                             //     $Type : 'UI.DataFieldForAction',
                             //     Action : 'DevelopmentService.calculateScore',
                             //     Label : 'calculateScore',
                             //     ![@UI.Hidden]: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
                             // },
                            ],
    UI.FieldGroup #metrics: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: difficulty,
            },
            {
                $Type: 'UI.DataField',
                Value: numberOfChanges,
            },
        ],
    },
    UI.HeaderFacets       : [{
        $Type : 'UI.ReferenceFacet',
        ID    : 'HistoricScore',
        Target: 'history/@UI.Chart#HistoricScore',
    }],
);

annotate service.DevelopmentObjects with @(
    UI.LineItem                          : [
        {
            $Type            : 'UI.DataField',
            Value            : system.sid,
            Label            : '{i18n>systemId}',
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>devClass}',
            Value            : devClass,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>namespace}',
            Value            : namespace,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectType}',
            Value            : objectType,
            ![@UI.Importance]: #High,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectName}',
            Value            : objectName,
            ![@UI.Importance]: #High,
        },
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>languageVersion}',
            Value                    : languageVersion_code,
            Criticality              : languageVersion.criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>scoreObject}',
            Value            : score,
            ![@UI.Importance]: #High,
        },
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>level}',
            Value                    : level,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : {$edmJson: {$If: [
                {$Eq: [
                    {$Path: 'level'},
                    'D'
                ]},
                1,
                {$If: [
                    {$Eq: [
                        {$Path: 'level'},
                        'C'
                    ]},
                    2,
                    {$If: [
                        {$Eq: [
                            {$Path: 'level'},
                            'B'
                        ]},
                        0,
                        3
                    ]}
                ]}
            ]}},
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>potentialLevel}',
            ![@UI.Importance]        : #Medium,
            Value                    : potentialLevel,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : {$edmJson: {$If: [
                {$Ne: [
                    {$Path: 'level'},
                    {$Path: 'potentialLevel'}
                ]},
                3,
                0
            ]}},
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>potentialScore}',
            Value            : potentialScore,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>cleanupPotential}',
            Value                : cleanupPotential,
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '5rem'},
        },
        {
            $Type                : 'UI.DataFieldForAnnotation',
            Label                : '{i18n>cleanupPotential}',
            Target               : '@UI.DataPoint#CleanupPotentialPercent',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '5rem'},


        },

        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'DevelopmentService.EntityContainer/recalculateAllScores',
            Label        : '{i18n>recalculateAllScores}',
            ![@UI.Hidden]: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
        },
        {
            $Type                : 'UI.DataField',
            Value                : difficulty,
            Label                : '{i18n>difficulty}',
            ![@UI.Importance]    : #Low,
            ![@HTML5.CssDefaults]: {width: '6rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : numberOfChanges,
            Label                : '{i18n>numberOfChanges}',
            ![@UI.Importance]    : #Low,
            ![@HTML5.CssDefaults]: {width: '6rem'},
        },
    ],
    UI.DataPoint #CleanupPotentialPercent: {
        $Type                    : 'UI.DataPointType',
        Title                    : '{i18n>CleanupPotentialPercent}',
        Value                    : cleanupPotentialPercent,
        ValueFormat              : {
            $Type                   : 'UI.NumberFormat',
            NumberOfFractionalDigits: 2,
            ScaleFactor             : 1
        },
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : {$edmJson: {$If: [
            {$Lt: [
                {$Path: 'cleanupPotentialPercent'},
                5
            ]},
            3,
            {$If: [
                {$Gt: [
                    {$Path: 'cleanupPotentialPercent'},
                    50
                ]},
                1,
                {$If: [
                    {$Gt: [
                        {$Path: 'cleanupPotentialPercent'},
                        25
                    ]},
                    2,
                    0
                ]}
            ]}
        ]}}
    },
    UI.FieldGroup #GeneratedGroup1       : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Label: '{i18n>objectType}',
                Value: objectType,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>objectName}',
                Value: objectName,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>devClass}',
                Value: devClass,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>languageVersion}',
                Value: languageVersion_code,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>score}',
                Value: score,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>level}',
                Value: level,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>potentialScore}',
                Value: potentialScore,
            },
            {
                $Type                : 'UI.DataField',
                Label                : '{i18n>potentialLevel}',
                Value                : potentialLevel,
                Criticality          : {$edmJson: {$If: [
                    {$Ne: [
                        {$Path: 'level'},
                        {$Path: 'potentialLevel'}
                    ]},
                    3,
                    0
                ]}},
                ![@HTML5.CssDefaults]: {width: '6rem'},
            }
        ],
    },
    UI.Facets                            : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneratedFacet1',
            Label : '{i18n>generalInformation}',
            Target: '@UI.FieldGroup#GeneratedGroup1',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>metrics}',
            ID    : 'metrics',
            Target: '@UI.FieldGroup#metrics',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>findings}',
            ID    : 'findingList',
            Target: 'findingList/@UI.SelectionPresentationVariant#findingList',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>usages}',
            ID    : 'usageList',
            Target: 'usageList/@UI.SelectionPresentationVariant#usageList',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>exemptions}',
            ID    : 'exemptionList',
            Target: 'exemptionList/@UI.SelectionPresentationVariant#exemptionList',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>scoreHistory}',
            ID    : 'ScoreHistory',
            Target: 'history/@UI.LineItem#ScoreHistory',
        },
    ]
);

annotate service.DevelopmentObjects with @(UI.SelectionFields: [
    systemId,
    objectType,
    objectName,
    devClass,
    namespace,
    languageVersion_code
]);

annotate service.DevelopmentObjects with {
    namespace               @Common.Label: '{i18n>namespace}';
    systemId                @Common.Label: '{i18n>systemId}';
    devClass                @Common.Label: '{i18n>devClass}';
    objectName              @Common.Label: '{i18n>objectName}';
    objectType              @Common.Label: '{i18n>objectType}';
    score                   @Common.Label: '{i18n>score}';
    difficulty              @Common.Label: '{i18n>difficulty}';
    numberOfChanges         @Common.Label: '{i18n>numberOfChanges}';
    cleanupPotential        @Common.Label: '{i18n>cleanupPotential}';
    cleanupPotentialPercent @Common.Label: '{i18n>cleanupPotentialPercent}';
    level                   @Common.Label: '{i18n>level}';
    potentialLevel          @Common.Label: '{i18n>potentialLevel}';
    potentialScore          @Common.Label: '{i18n>potentialScore}';
    softwareComponent       @Common.Label: '{i18n>softwareComponent}';
};

annotate service.DevelopmentObjects with @(UI.SelectionPresentationVariant #table: {
    $Type              : 'UI.SelectionPresentationVariantType',
    PresentationVariant: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.LineItem',
        ],
        GroupBy       : [],
        Total         : [score // This shit doesn't work?!
        ],
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : score,
            Descending: true,
        }, ],
    },
    SelectionVariant   : {
        $Type        : 'UI.SelectionVariantType',
        SelectOptions: [{
            $Type       : 'UI.SelectOptionType',
            PropertyName: devClass,
            Ranges      : [{
                Sign  : #E,
                Option: #EQ,
                Low   : '$TMP',
            }, ],
        }, ],
    },
});

annotate service.DevelopmentObjects with @(UI.HeaderInfo: {
    Title         : {
        $Type: 'UI.DataField',
        Value: '{objectType} - {objectName}',
    },
    TypeName      : '',
    TypeNamePlural: '',
});


annotate service.DevelopmentObjects with {
    languageVersion_code @Common.Text: {
        $value                : languageVersion.title,
        ![@UI.TextArrangement]: #TextFirst,
    }
};

annotate service.DevelopmentObjectsFindings with @(
    UI.LineItem #findingList                    : [
        {
            $Type                : 'UI.DataField',
            Value                : refObjectName,
            Label                : '{i18n>refObjectName}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '18rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : refObjectType,
            Label                : '{i18n>refObjectType}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : code,
            Label                    : '{i18n>rating}',
            Criticality              : rating.criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #High,
            ![@HTML5.CssDefaults]    : {width: '16rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : rating.level,
            Label                    : '{i18n>level}',
            Criticality              : rating.criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #Medium,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : rating.score,
            Label                    : '{i18n>score}',
            Criticality              : rating.criticality.criticality,
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
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>potentialScore}',
            Value                    : potentialRating.score,
            Criticality              : potentialRating.criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>potentialLevel}',
            Value                    : potentialRating.level,
            Criticality              : potentialRating.criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        }
    ],
    UI.SelectionPresentationVariant #findingList: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem#findingList',
            ],
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
    }
);

annotate service.DevelopmentObjectUsages with @(
    UI.SelectionPresentationVariant #usageList: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem#usageList',
            ],
            SortOrder     : [{
                $Type     : 'Common.SortOrderType',
                Property  : counter,
                Descending: true,
            }, ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
    UI.LineItem #usageList                    : [
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>entryPointObjectType}',
            Value                : entryPointObjectType,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>entryPointObjectName}',
            Value                : entryPointObjectName,
            ![@HTML5.CssDefaults]: {width: '18rem'},
        },
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>counter}',
            Value                : counter,
            ![@HTML5.CssDefaults]: {width: '6rem'},
            ![@UI.Importance]    : #Medium,
        },
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>lastUsed}',
            Value                : lastUsed,
            ![@HTML5.CssDefaults]: {width: '8rem'},
            ![@UI.Importance]    : #Low,
        },
    ]
);

annotate service.DevelopmentObjectUsages with {
    entryPointObjectName @Common.Label: '{i18n>entryPointObjectName}';
    entryPointObjectType @Common.Label: '{i18n>entryPointObjectType}';
    counter              @Common.Label: '{i18n>counter}';
    lastUsed             @Common.Label: '{i18n>lastUsed}';
};

annotate service.DevelopmentObjectsFindings with {
    code @(
        Common.Text                    : rating.title,
        Common.Text.@UI.TextArrangement: #TextFirst,
    )
};

annotate service.HistoricDevelopmentObjects with @(
    UI.DataPoint #HistoricScore: {
        Value      : score,
        Criticality: #Positive
    },
    UI.Chart #HistoricScore    : {
        ChartType          : #Line,
        Title              : '{i18n>scoreHistory}',
        Measures           : [score, ],
        MeasureAttributes  : [{
            DataPoint: '@UI.DataPoint#HistoricScore',
            Role     : #Axis1,
            Measure  : score,
        }, ],
        Dimensions         : [versionNumber],
        DimensionAttributes: [

        ]
    },
    UI.LineItem #ScoreHistory  : [
        {
            $Type: 'UI.DataField',
            Value: versionNumber,
            Label: '{i18n>versionNumber}',
        },
        {
            $Type: 'UI.DataField',
            Value: createdAt,
            Label: '{i18n>createdAt}',
        },
        {
            $Type: 'UI.DataField',
            Value: score,
            Label: '{i18n>score}',
        },
        {
            $Type: 'UI.DataField',
            Value: level,
            Label: '{i18n>level}',
        },
    ],
);

annotate service.Exemptions with @(
    UI.SelectionPresentationVariant #exemptionList: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem#exemptionList',
            ],
            SortOrder     : [{
                $Type     : 'Common.SortOrderType',
                Property  : rating.score,
                Descending: true,
            }, ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
    UI.LineItem #exemptionList                    : [
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
            Value                    : messageId,
            ![@UI.Importance]        : #High,
            ![@HTML5.CssDefaults]    : {width: '12rem'},
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : rating.criticality.criticality,
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
            $Type                    : 'UI.DataField',
            Value                    : objectScope_code,
            Label                    : '{i18n>objectScope}',
            ![@UI.Importance]        : #Medium,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : objectScope.criticality.criticality,
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
            $Type            : 'UI.DataField',
            Value            : checkClass,
            Label            : '{i18n>checkClass}',
            ![@UI.Importance]: #Low,
        },
        {
            $Type          : 'UI.DataFieldForIntentBasedNavigation',
            SemanticObject : 'Exemptions',
            Action         : 'manage',
            Label          : 'Manage Exemptions',
            Inline         : false,
            RequiresContext: false,
            Mapping        : [
                {
                    $Type                 : 'Common.SemanticObjectMappingType',
                    LocalProperty         : objectName,
                    SemanticObjectProperty: 'objectName',
                }
            ]
        },
    ],
);

// CRUD operations
annotate service.DevelopmentObjects with @(
    UI.CreateHidden: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
    UI.UpdateHidden: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
    UI.DeleteHidden: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}}
);
