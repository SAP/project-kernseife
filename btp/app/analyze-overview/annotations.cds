using AnalyticsService as service from '../../srv/analytics-service';


annotate service.DevelopmentObjects with @(
    UI.Chart #languageVersionShare                                    : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>languageVersionShare}',
        ChartType          : #Donut,
        Dimensions         : [languageVersion_code],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: languageVersion_code,
            Role     : #Category
        }],
        Measures           : [objectCount],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: objectCount,
            Role   : #Axis1,
        }]
    },
    UI.PresentationVariant #languageVersionShare                      : {
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : languageVersion_code,
            Descending: true
        }],
        Visualizations: ['@UI.Chart#languageVersionShare']
    },
    UI.DataPoint #languageVersionShare                                : {
        $Type: 'UI.DataPointType',
        Value: objectCount,
        Title: '{i18n>languageVersionShare}',
    },
    UI.Identification #languageVersionShare                           : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        SemanticObject: 'DevelopmentObjects',
        Action        : 'manage',
    }, ],
    UI.Chart #scoreShare                                              : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>scoreShare}',
        ChartType          : #Donut,
        Dimensions         : [level],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: level,
            Role     : #Category
        }],
        Measures           : [score],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: score,
            Role   : #Axis1
        }]
    },
    UI.PresentationVariant #scoreShare                                : {
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : level,
            Descending: false,

        }],
        Visualizations: ['@UI.Chart#scoreShare']
    },
    UI.DataPoint #scoreShare                                          : {
        $Type: 'UI.DataPointType',
        Value: score,
        Title: '{i18n>scoreShare}',
    },
    UI.Identification #scoreShare                                     : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        Label         : '{i18n>score}',
        SemanticObject: 'DevelopmentObjects',
        Action        : 'manage',
    }, ],
    UI.Chart #levelShare                                              : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>levelShare}',
        ChartType          : #Donut,
        Dimensions         : [level],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: level,
            Role     : #Category
        }],
        Measures           : [objectCount],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: objectCount,
            Role   : #Axis1,
        }]
    },
    UI.PresentationVariant #levelShare                                : {
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : level,
            Descending: false,

        }],
        Visualizations: ['@UI.Chart#levelShare']
    },
    UI.DataPoint #levelShare                                          : {
        $Type: 'UI.DataPointType',
        Value: objectCount,
        Title: '{i18n>levelShare}',

    },
    UI.Identification #levelShare                                     : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        SemanticObject: 'DevelopmentObjects',
        Action        : 'manage',
    }, ],
    UI.Chart #potentialLevelShare                                     : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>potentialLevelShare}',
        ChartType          : #Donut,
        Dimensions         : [potentialLevel],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: potentialLevel,
            Role     : #Category
        }],
        Measures           : [objectCount],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: objectCount,
            Role   : #Axis1,
        }]
    },
    UI.PresentationVariant #potentialLevelShare                       : {
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : potentialLevel,
            Descending: false,

        }],
        Visualizations: ['@UI.Chart#potentialLevelShare']
    },
    UI.DataPoint #potentialLevelShare                                 : {
        $Type: 'UI.DataPointType',
        Value: objectcount,
        Title: '{i18n>potentialLevelShare}',

    },
    UI.Identification #potentialLevelShare                            : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        SemanticObject: 'DevelopmentObjects',
        Action        : 'manage',
    }, ],
    UI.LineItem #topDevelopmentObjectsByScore                         : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectType}',
            ![@UI.Importance]: #High,
            Value            : objectType
        },
        {
            Value                               : objectName,
            Label                               : '{i18n>objectName}',
            UI.DataFieldForIntentBasedNavigation: {
                SemanticObject: 'DevelopmentObjects',
                Action        : 'manage',
                Label         : '{i18n>manage}',
                Parameters    : [
                    {$PropertyPath: 'objectName'},
                    {$PropertyPath: 'objectType'}
                ]
            }
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>level}',
            ![@UI.Importance]: #Low,
            Value            : level
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>score}',
            ![@UI.Importance]: #Low,
            Value            : score
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>cleanupPotential}',
            ![@UI.Importance]: #Low,
            Value            : cleanupPotential
        },
        {
            $Type            : 'UI.DataFieldForAnnotation',
            Target           : '@UI.DataPoint#cleanupPotentialPercent',
            Label            : '{i18n>cleanupPotentialPercent}',
            ![@UI.Importance]: #Low,
        },
    ],
    UI.LineItem #topDevelopmentObjectsByCleanupPotentialAbs           : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectType}',
            ![@UI.Importance]: #High,
            Value            : objectType
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectName}',
            ![@UI.Importance]: #High,
            Value            : objectName,

        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>level}',
            ![@UI.Importance]: #Low,
            Value            : level
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>score}',
            ![@UI.Importance]: #Low,
            Value            : score
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>cleanupPotential}',
            ![@UI.Importance]: #Low,
            Value            : cleanupPotential
        },
        {
            $Type            : 'UI.DataFieldForAnnotation',
            Target           : '@UI.DataPoint#cleanupPotentialPercent',
            Label            : '{i18n>cleanupPotentialPercent}',
            ![@UI.Importance]: #Low,
        },
    ],
    UI.LineItem #topDevelopmentObjectsByCleanupPotentialRel           : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectType}',
            ![@UI.Importance]: #High,
            Value            : objectType
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectName}',
            ![@UI.Importance]: #High,
            Value            : objectName,

        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>level}',
            ![@UI.Importance]: #Low,
            Value            : level
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>score}',
            ![@UI.Importance]: #Low,
            Value            : score
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>cleanupPotential}',
            ![@UI.Importance]: #Low,
            Value            : cleanupPotential
        },
        {
            $Type            : 'UI.DataFieldForAnnotation',
            Target           : '@UI.DataPoint#cleanupPotentialPercent',
            Label            : '{i18n>cleanupPotentialPercent}',
            ![@UI.Importance]: #Low,
        },
    ],
    UI.DataPoint #cleanupPotentialPercent                             : {
        $Type      : 'UI.DataPointType',
        Title      : '{i18n>CleanupPotentialPercent}',
        Value      : cleanupPotentialPercent,
        ValueFormat: {
            NumberOfFractionalDigits: 2,
            ScaleFactor             : 1,
        }
    },
    UI.PresentationVariant #topDevelopmentObjectsByScore              : {SortOrder: [{
        Property  : score,
        Descending: true
    }, ]},
    UI.PresentationVariant #topDevelopmentObjectsByCleanupPotentialAbs: {SortOrder: [{
        Property  : cleanupPotential,
        Descending: true
    }, ]},
    UI.PresentationVariant #topDevelopmentObjectsByCleanupPotentialRel: {SortOrder: [{
        Property  : cleanupPotentialPercent,
        Descending: true
    }, ]},
    UI.Chart #cleanupPotential                                        : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>cleanupPotential}',
        ChartType          : #ColumnStacked,
        Dimensions         : [],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: objectName,
            Role     : #Category
        }],
        Measures           : [
            score,
            potentialScore
        ],
        MeasureAttributes  : [
            {
                $Type    : 'UI.ChartMeasureAttributeType',
                Measure  : cleanupPotential,
                DataPoint: '@UI.DataPoint#cleanupPotential',
                Role     : #Axis1,
            },
            {
                $Type    : 'UI.ChartMeasureAttributeType',
                Measure  : potentialScore,
                DataPoint: '@UI.DataPoint#potentialScore',
                Role     : #Axis2,
            }
        ]
    },
    UI.PresentationVariant #cleanupPotential                          : {
        MaxItems      : 8,
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : score,
            Descending: true,

        }],
        Visualizations: ['@UI.Chart#cleanupPotential']
    },
    UI.DataPoint #cleanupPotential                                    : {
        $Type      : 'UI.DataPointType',
        Value      : cleanupPotential,
        Title      : '{i18n>cleanupPotential}',
        Description: '{i18n>cleanupPotential}',
        Criticality: #Positive
    },
    UI.DataPoint #potentialScore                                      : {
        $Type      : 'UI.DataPointType',
        Value      : potentialScore,
        Title      : '{i18n>potentialScore}',
        Description: '{i18n>potentialScore}',
        Criticality: #Neutral
    },


    UI.Identification #cleanupPotential                               : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        SemanticObject: 'DevelopmentObjects',
        Action        : 'manage',
    }, ]
);

annotate service.Classifications with @(
    UI.Chart #ratingShare              : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>ratingShare}',
        ChartType          : #Column,
        Dimensions         : [rating_code],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: rating_code,
            Role     : #Category
        }],
        Measures           : [objectCount],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: objectCount,
            Role   : #Axis1,
        }]
    },
    UI.PresentationVariant #ratingShare: {
        MaxItems      : 8,
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : objectCount,
            Descending: true,

        }],
        Visualizations: ['@UI.Chart#ratingShare']
    },
    UI.DataPoint #ratingShare          : {
        $Type      : 'UI.DataPointType',
        Value      : objectCount,
        Title      : '{i18n>ratingShare}',
        Description: '{i18n>objectCount}',
    },

    UI.Identification #ratingShare     : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        SemanticObject: 'Classifications',
        Action        : 'manage',
    }, ]


);


annotate service.DevClasses with @(
    UI.LineItem #topPackagesByScoreSum                   : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>devClass}',
            ![@UI.Importance]: #High,
            Value            : devClass,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>level}',
            ![@UI.Importance]: #Low,
            Value            : level
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>potentialLevel}',
            ![@UI.Importance]: #Low,
            Value            : potentialLevel
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>score}',
            ![@UI.Importance]: #High,
            Value            : score
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectCount}',
            ![@UI.Importance]: #Low,
            Value            : objectCount
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>cleanupPotential}',
            ![@UI.Importance]: #Low,
            Value            : cleanupPotential
        },

        {
            $Type            : 'UI.DataFieldForAnnotation',
            Target           : '@UI.DataPoint#AverageScore',
            Label            : '{i18n>averageScore}',
            ![@UI.Importance]: #Low,
        }
    ],
    UI.LineItem #topPackagesByScoreAvg                   : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>devClass}',
            ![@UI.Importance]: #High,
            Value            : devClass,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>level}',
            ![@UI.Importance]: #Low,
            Value            : level
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>potentialLevel}',
            ![@UI.Importance]: #Low,
            Value            : potentialLevel
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectCount}',
            ![@UI.Importance]: #Low,
            Value            : objectCount
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>cleanupPotential}',
            ![@UI.Importance]: #Low,
            Value            : cleanupPotential
        },
        {
            $Type            : 'UI.DataFieldForAnnotation',
            Target           : '@UI.DataPoint#AverageScore',
            Label            : '{i18n>averageScore}',
            ![@UI.Importance]: #High,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>score}',
            ![@UI.Importance]: #Low,
            Value            : score
        }
    ],
    UI.LineItem #topPackagesByObjectCount                : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>devClass}',
            ![@UI.Importance]: #High,
            Value            : devClass,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>level}',
            ![@UI.Importance]: #Low,
            Value            : level
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>potentialLevel}',
            ![@UI.Importance]: #Low,
            Value            : potentialLevel
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectCount}',
            ![@UI.Importance]: #High,
            Value            : objectCount
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>cleanupPotential}',
            ![@UI.Importance]: #Low,
            Value            : cleanupPotential
        },
        {
            $Type            : 'UI.DataFieldForAnnotation',
            Target           : '@UI.DataPoint#AverageScore',
            Label            : '{i18n>averageScore}',
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>score}',
            ![@UI.Importance]: #Low,
            Value            : score
        }
    ],
    UI.LineItem #topPackagesByCleanupPotential           : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>devClass}',
            ![@UI.Importance]: #High,
            Value            : devClass,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>level}',
            ![@UI.Importance]: #Low,
            Value            : level
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>potentialLevel}',
            ![@UI.Importance]: #Low,
            Value            : potentialLevel
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectCount}',
            ![@UI.Importance]: #Low,
            Value            : objectCount
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>cleanupPotential}',
            ![@UI.Importance]: #High,
            Value            : cleanupPotential
        },
        {
            $Type            : 'UI.DataFieldForAnnotation',
            Target           : '@UI.DataPoint#AverageScore',
            Label            : '{i18n>averageScore}',
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>score}',
            ![@UI.Importance]: #Low,
            Value            : score
        }
    ],
    UI.DataPoint #AverageScore                           : {
        $Type      : 'UI.DataPointType',
        Title      : '{i18n>averageScore}',
        Value      : averageScore,
        ValueFormat: {
            NumberOfFractionalDigits: 0,
            ScaleFactor             : 1,
        }
    },

    UI.PresentationVariant #topPackagesByScoreSum        : {SortOrder: [{
        Property  : score,
        Descending: true,

    }, ], },
    UI.PresentationVariant #topPackagesByScoreAvg        : {SortOrder: [{
        Property  : averageScore,
        Descending: true
    }, ]},
    UI.PresentationVariant #topPackagesByObjectCount     : {SortOrder: [{
        Property  : objectCount,
        Descending: true
    }, ]},
    UI.PresentationVariant #topPackagesByCleanupPotential: {SortOrder: [{
        Property  : cleanupPotential,
        Descending: true
    }, ]},
    UI.Chart #cleanupPotential                           : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>cleanupPotential}',
        ChartType          : #ColumnStacked,
        Dimensions         : [],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: devClass,
            Role     : #Category,
        }],
        Measures           : [
            cleanupPotential,
            potentialScore
        ],
        MeasureAttributes  : [
            {
                $Type    : 'UI.ChartMeasureAttributeType',
                Measure  : cleanupPotential,
                Role     : #Axis1,
                DataPoint: '@UI.DataPoint#cleanupPotential',
            },
            {
                $Type    : 'UI.ChartMeasureAttributeType',
                Measure  : potentialScore,
                Role     : #Axis1,
                DataPoint: '@UI.DataPoint#potentialScore',
            }
        ]
    },
    UI.DataPoint #cleanupPotential                       : {
        $Type      : 'UI.DataPointType',
        Value      : cleanupPotential,
        Title      : '{i18n>cleanupPotential}',
        Description: '{i18n>cleanupPotential}',
        Criticality: #Positive
    },
    UI.DataPoint #potentialScore                         : {
        $Type      : 'UI.DataPointType',
        Value      : potentialScore,
        Title      : '{i18n>potentialScore}',
        Description: '{i18n>potentialScore}',
        Criticality: #Neutral
    },
    UI.PresentationVariant #cleanupPotential             : {
        MaxItems      : 8,
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : score,
            Descending: true,

        }],
        Visualizations: ['@UI.Chart#cleanupPotential']
    },

    UI.Identification #cleanupPotential                  : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        SemanticObject: 'DevelopmentObjects',
        Action        : 'manage',
    }, ],
);

annotate service.ScoreHistory with @(UI.Chart #scoreHistory: {
    $Type              : 'UI.ChartDefinitionType',
    Description        : '{i18n>scoreHistoryDescription}',
    Title              : '{i18n>scoreHistory}',
    ChartType          : #Line,
    Dimensions         : [
        createdAt,
        systemId
    ],
    DimensionAttributes: [
        {
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: createdAt,
            Role     : #Category,

        },
        {
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: systemId,
            Role     : #Series,
        }
    ],
    Measures           : [score],
    MeasureAttributes  : [{
        $Type  : 'UI.ChartMeasureAttributeType',
        Measure: score,
        Role   : #Axis1,
    }],
});

annotate service.Exemptions with @(
    UI.PresentationVariant #exemptionHistory: {
        MaxItems      : 8,
        GroupBy       : [
            systemId,
            state
        ],
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : objectCount,
            Descending: true,

        }],
        Visualizations: ['@UI.Chart#exemptionHistory']
    },
    UI.Identification #exemptionHistory     : [{
        $Type         : 'UI.DataFieldForIntentBasedNavigation',
        SemanticObject: 'Exemptions',
        Action        : 'manage',

    }, ],
    UI.DataPoint #exemptionHistory          : {
        $Type      : 'UI.DataPointType',
        Title      : '{i18n>exemtions}',
        Description: '{i18n>exemtions}',
        value      : objectCount,
        ValueFormat: {
            ScaleFactor             : 1000,
            NumberOfFractionalDigits: 0
        },
    },
    UI.Chart #exemptionHistory              : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>exemptionHistory}',
        ChartType          : #ColumnStacked,
        Dimensions         : [
            systemId,
            state
        ],
        Measures           : [objectCount],
        DimensionAttributes: [
            {
                $Type    : 'UI.ChartDimensionAttributeType',
                Dimension: systemId,
                Role     : #Category,
            },
            {
                $Type    : 'UI.ChartDimensionAttributeType',
                Dimension: state,
                Role     : #Series,
            }
        ],
        MeasureAttributes  : [{
            $Type    : 'UI.ChartMeasureAttributeType',
            Measure  : objectCount,
            Role     : #Axis1,
            DataPoint: '@UI.DataPoint#exemptionHistory',
        }, ],

    },
    UI.Chart #objectScope                   : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>objectScope}',
        ChartType          : #Donut,
        Dimensions         : [objectScope],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: objectScope,
            Role     : #Category
        }],
        Measures           : [objectCount],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: objectCount,
            Role   : #Axis1
        }]
    },
    UI.PresentationVariant #objectScope     : {
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : objectScope,
            Descending: false,

        }],
        Visualizations: ['@UI.Chart#objectScope']
    },
    UI.DataPoint #objectScope                : {
        $Type: 'UI.DataPointType',
        Value: objectCount,
        Title: '{i18n>checkScope}',
    },
    UI.Chart #checkScope                    : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>checkScope}',
        ChartType          : #Donut,
        Dimensions         : [checkScope],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: checkScope,
            Role     : #Category
        }],
        Measures           : [objectCount],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: objectCount,
            Role   : #Axis1
        }]
    },
    UI.PresentationVariant #checkScope      : {
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : checkScope,
            Descending: false,

        }],
        Visualizations: ['@UI.Chart#checkScope']
    },
    UI.DataPoint #checkScope              : {
        $Type: 'UI.DataPointType',
        Value: objectCount,
        Title: '{i18n>reason}',
    },
     UI.Chart #reason                    : {
        $Type              : 'UI.ChartDefinitionType',
        Title              : '{i18n>reason}',
        ChartType          : #Donut,
        Dimensions         : [reason],
        DimensionAttributes: [{
            $Type    : 'UI.ChartDimensionAttributeType',
            Dimension: reason,
            Role     : #Category
        }],
        Measures           : [objectCount],
        MeasureAttributes  : [{
            $Type  : 'UI.ChartMeasureAttributeType',
            Measure: objectCount,
            Role   : #Axis1
        }]
    },
    UI.PresentationVariant #reason      : {
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : reason,
            Descending: false,

        }],
        Visualizations: ['@UI.Chart#reason']
    },
    UI.DataPoint #reason                : {
        $Type: 'UI.DataPointType',
        Value: objectCount,
        Title: '{i18n>reason}',
    },
);
