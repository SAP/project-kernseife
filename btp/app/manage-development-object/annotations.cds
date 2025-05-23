using AdminService as service from '../../srv/admin-service';

annotate service.DevelopmentObjects with @(
    Capabilities: {FilterFunctions: ['tolower', ]},
    UI.Identification : [
        // {
        //     $Type : 'UI.DataFieldForAction',
        //     Action : 'AdminService.calculateScore',
        //     Label : 'calculateScore',
        // },
    ],
);

annotate service.DevelopmentObjects with @(UI.LineItem: [
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
        Value                    : cleanCoreScore,
        Criticality              : {$edmJson: {$If: [
            {$Lt: [
                {$Path: 'cleanCoreScore'},
                1
            ]},
            0,
            {$If: [
                {$Gt: [
                    {$Path: 'cleanCoreScore'},
                    4.99
                ]},
                3,
                2
            ]}
        ]}},
        CriticalityRepresentation: #WithoutIcon,

    },
    {
        $Type: 'UI.DataField',
        Label: '{i18n>cleanCoreLevel}',
        Value: cleanCoreLevel.title,
    },
     {
        $Type : 'UI.DataFieldForAction',
         Action: 'AdminService.EntityContainer/recalculateAllScores',
        Label : '{i18n>recalculateAllScores}',
    },
]);

annotate service.DevelopmentObjects with @(
    UI.FieldGroup #GeneratedGroup1: {
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
                Label: '{i18n>cleanCoreLevel}',
                Value: cleanCoreLevel.title,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>cleanCoreScore}',
                Value: cleanCoreScore,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>score}',
                Value: score,
            }
        ],
    },
    UI.Facets                     : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneratedFacet1',
            Label : '{i18n>generalInformation}',
            Target: '@UI.FieldGroup#GeneratedGroup1',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>findings}',
            ID    : 'findingList',
            Target: 'findingListAggregated/@UI.SelectionPresentationVariant#findingList',
        },
    ]
);

annotate service.DevelopmentObjects with @(UI.SelectionFields: [
    systemId,
    devClass,
    namespace,
    objectType,
    languageVersion_code,
    cleanCoreLevel_code
]);

annotate service.DevelopmentObjects with {
    namespace      @Common.Label: '{i18n>namespace}';
    systemId       @Common.Label: '{i18n>systemId}';
    devClass       @Common.Label: '{i18n>devClass}';
    objectType     @Common.Label: '{i18n>objectType}';
    cleanCoreScore @Common.Label: '{i18n>cleanCoreScore}';
    cleanCoreLevel @Common.Label: '{i18n>cleanCoreLevel}';
};

annotate service.DevelopmentObjects with @(UI.SelectionPresentationVariant #table: {
    $Type              : 'UI.SelectionPresentationVariantType',
    PresentationVariant: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.LineItem', ],
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

annotate service.ScoringFindingsAggregated with @(
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

        }
    ],
    UI.SelectionPresentationVariant #findingList: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem#findingList', ],
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
