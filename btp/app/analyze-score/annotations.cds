using AnalyticsService as service from '../../srv/analytics-service';

annotate service.DevelopmentObjects with @(Capabilities: {FilterFunctions: ['tolower', ]});

annotate service.DevelopmentObjects with @(

    Aggregation.ApplySupported                     : {
        Transformations       : [
            'aggregate',
            'topcount',
            'bottomcount',
            'identity',
            'concat',
            'groupby',
            'filter',
            'search'
        ],
        GroupableProperties   : [
            devClass,
            systemId,
            extension,
            languageVersion_code,
            cleanCoreLevel_code,
            namespace
        ],
        AggregatableProperties: [
            {
                $Type   : 'Aggregation.AggregatablePropertyType',
                Property: score
            },
            {
                $Type   : 'Aggregation.AggregatablePropertyType',
                Property: cleanCoreScore
            }
        ]
    },
    Analytics.AggregatedProperty #totalScore       : {
        $Type               : 'Analytics.AggregatedPropertyType',
        AggregatableProperty: score,
        AggregationMethod   : 'sum',
        Name                : 'totalScore',
        ![@Common.Label]    : '{i18n>totalScore}'
    },
    Analytics.AggregatedProperty #avgCleanCoreScore: {
        $Type               : 'Analytics.AggregatedPropertyType',
        AggregatableProperty: cleanCoreScore,
        AggregationMethod   : 'average',
        Name                : 'avgCleanCoreScore',
        ![@Common.Label]    : '{i18n>avgCleanCoreScore}'
    },
);


annotate service.DevelopmentObjects with @(
    UI.Chart              : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>score}',
        ChartType          : #Column,
        Dimensions         : [devClass],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: devClass,
            Role     : #Category
        }],
        DynamicMeasures    : [
            ![@Analytics.AggregatedProperty#totalScore],
            ![@Analytics.AggregatedProperty#avgCleanCoreScore]
        ],
        MeasureAttributes  : [
            {
                $Type         : 'UI.ChartMeasureAttributeType',
                DynamicMeasure: ![@Analytics.AggregatedProperty#totalScore],
                Role          : #Axis1,

            },
            {
                $Type         : 'UI.ChartMeasureAttributeType',
                DynamicMeasure: ![@Analytics.AggregatedProperty#avgCleanCoreScore],
                Role          : #Axis1,

            }
        ]
    },
    UI.PresentationVariant: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.Chart', ],
        SortOrder     : [{
            $Type          : 'Common.SortOrderType',
            DynamicProperty: '@Analytics.AggregatedProperty#totalScore',
            Descending     : true,
        }, ],
    }
);

annotate service.DevelopmentObjects with @(
    UI.Chart #devClass                  : {
        $Type          : 'UI.ChartDefinitionType',
        ChartType      : #Bar,
        Dimensions     : [devClass],
        DynamicMeasures: [ ![@Analytics.AggregatedProperty#totalScore] ]
    },
    UI.PresentationVariant #prevdevClass: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.Chart#devClass', ],
    }
) {
    devClass @Common.ValueList #vlDevClass: {
        $Type                       : 'Common.ValueListType',
        CollectionPath              : 'DevelopmentObjects',
        Parameters                  : [{
            $Type            : 'Common.ValueListParameterInOut',
            ValueListProperty: 'devClass',
            LocalDataProperty: devClass
        }],
        PresentationVariantQualifier: 'prevdevClass'
    }
}

//systemId
annotate service.DevelopmentObjects with @(
    UI.Chart #systemId                  : {
        $Type              : 'UI.ChartDefinitionType',
        ChartType          : #Bar,
        Dimensions         : [systemId],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: systemId,
            Role     : #Category
        }],
        DynamicMeasures    : [ ![@Analytics.AggregatedProperty#totalScore] ]
    },
    UI.PresentationVariant #prevSystemId: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.Chart#systemId', ],
    }
);

//extension
annotate service.DevelopmentObjects with @(
    UI.Chart #extension                  : {
        $Type              : 'UI.ChartDefinitionType',
        ChartType          : #Bar,
        Dimensions         : [extension],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: extension,
            Role     : #Category
        }],
        DynamicMeasures    : [ ![@Analytics.AggregatedProperty#totalScore] ]
    },
    UI.PresentationVariant #prevExtension: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.Chart#extension', ],
    }
) {
    extension @Common.ValueList #vlExtension: {
        $Type                       : 'Common.ValueListType',
        CollectionPath              : 'DevelopmentObjects',
        Parameters                  : [{
            $Type            : 'Common.ValueListParameterInOut',
            ValueListProperty: 'extension',
            LocalDataProperty: extension
        }],
        PresentationVariantQualifier: 'prevExtension'
    }
}

//namespace
annotate service.DevelopmentObjects with @(
    UI.Chart #namespace                  : {
        $Type              : 'UI.ChartDefinitionType',
        ChartType          : #Bar,
        Dimensions         : [namespace],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: namespace,
            Role     : #Category
        }],
        DynamicMeasures    : [ ![@Analytics.AggregatedProperty#totalScore] ]
    },
    UI.PresentationVariant #prevNamespace: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.Chart#namespace', ],
    }
);

//languageVersion
annotate service.DevelopmentObjects with @(
    UI.Chart #languageVersion                  : {
        $Type              : 'UI.ChartDefinitionType',
        ChartType          : #Bar,
        Dimensions         : [languageVersion_code],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: languageVersion_code,
            Role     : #Category
        }],
        DynamicMeasures    : [ ![@Analytics.AggregatedProperty#totalScore] ]
    },
    UI.PresentationVariant #prevLanguageVersion: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.Chart#languageVersion', ],
    }
) {
    languageVersion_code @Common.ValueList #vlLanguageVersion: {
        $Type                       : 'Common.ValueListType',
        CollectionPath              : 'DevelopmentObjects',
        Parameters                  : [{
            $Type            : 'Common.ValueListParameterInOut',
            ValueListProperty: 'languageVersion_code',
            LocalDataProperty: languageVersion_code
        }],
        PresentationVariantQualifier: 'prevLanguageVersion'
    }
}

//cleanCoreLevel
annotate service.DevelopmentObjects with @(
    UI.Chart #cleanCoreLevel                  : {
        $Type              : 'UI.ChartDefinitionType',
        ChartType          : #Bar,
        Dimensions         : [cleanCoreLevel_code],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: cleanCoreLevel_code,
            Role     : #Category
        }],
        DynamicMeasures    : [ ![@Analytics.AggregatedProperty#totalScore] ]
    },
    UI.PresentationVariant #prevCleanCoreLevel: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.Chart#cleanCoreLevel', ],
    }
) {
    cleanCoreLevel @Common.ValueList #vlCleanCoreLevel: {
        $Type                       : 'Common.ValueListType',
        CollectionPath              : 'DevelopmentObjects',
        Parameters                  : [{
            $Type            : 'Common.ValueListParameterInOut',
            ValueListProperty: 'cleanCoreLevel_code',
            LocalDataProperty: cleanCoreLevel_code
        }],
        PresentationVariantQualifier: 'prevCleanCoreLevel'
    }
}

annotate service.DevelopmentObjects with @(UI: {
    SelectionFields: [
        devClass,
        systemId,
        extension_ID,
        namespace,
        objectType,
        cleanCoreLevel_code,
    ],
    LineItem       : [
        {
            $Type                : 'UI.DataField',
            Value                : systemId,
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '8rem'},
        },
        {
            $Type            : 'UI.DataField',
            Value            : extension,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type                : 'UI.DataField',
            Value                : devClass,
            ![@UI.Importance]    : #Low,
            ![@HTML5.CssDefaults]: {width: '13rem'},
        },

        {
            $Type                : 'UI.DataField',
            Value                : objectType,
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : objectName,
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '15rem'},
        },
        {
            $Type            : 'UI.DataField',
            Value            : languageVersion_code,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Value            : cleanCoreLevel.title,
            Label            : '{i18n>cleanCoreLevel}',
            ![@UI.Importance]: #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Value            : score,
            ![@UI.Importance]: #High,
        },
        {
            $Type            : 'UI.DataField',
            Value            : cleanCoreScore,
            ![@UI.Importance]: #High,
        },
    ],
});

annotate service.DevelopmentObjects with {
    devClass             @Common.Label: '{i18n>devClass}';
    objectName           @Common.Label: '{i18n>objectName}';
    objectType           @Common.Label: '{i18n>objectType}';
    systemId             @Common.Label: '{i18n>systemId}';
    extension            @Common.Label: '{i18n>extension}';
    @Common.Label: '{i18n>cleanCoreLevel}'
    @UI.HiddenFilter
    @Common.Text : {
        $value                : cleanCoreLevel.title,
        ![@UI.TextArrangement]: #TextOnly,
    }
    cleanCoreLevel;
    @Common.Label: '{i18n>extension}'
    @UI.HiddenFilter
    @Common.Text : {
        $value                : extension,
        ![@UI.TextArrangement]: #TextOnly,
    }
    extension_ID;
    languageVersion_code @Common.Label: '{i18n>languageVersion}';
    score                @Common.Label: '{i18n>score}';
    cleanCoreScore       @Common.Label: '{i18n>cleanCoreScore}';
};

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
    TypeName      : '{i18n>developmentObject}',
    TypeNamePlural: '{i18n>developmentObjects}',
});


annotate service.DevelopmentObjects with @(
    UI.FieldGroup #GeneratedGroup1: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: objectType,
            },
            {
                $Type: 'UI.DataField',
                Value: objectName,
            },
            {
                $Type: 'UI.DataField',
                Value: devClass,
            },
            {
                $Type: 'UI.DataField',
                Value: extension_ID,
            },
            {
                $Type: 'UI.DataField',
                Value: languageVersion_code,
            },
            {
                $Type: 'UI.DataField',
                Value: cleanCoreLevel.title,
            },
            {
                $Type: 'UI.DataField',
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

annotate service.CleanCoreLevel with {
    code @Common.Label: 'cleanCoreLevel/code'
};
