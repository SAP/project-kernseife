using DevelopmentService as service from '../../srv/development-service';

annotate service.Extensions with @Capabilities: {FilterFunctions: ['tolower', ]};

annotate service.Extensions with @(
    UI.FieldGroup #generalInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: title,
            },
            {
                $Type: 'UI.DataField',
                Value: system_ID,
            },
        ],
    },
    UI.Facets                        : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'generalInformation',
            Label : '{i18n>generalInformation}',
            Target: '@UI.FieldGroup#generalInformation',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>developmentObjectList}',
            ID    : 'developmentObjectList',
            Target: 'developemtObjectList/@UI.LineItem#developmentObjectList',
        },
    ],
    UI.LineItem                      : [
        {
            $Type: 'UI.DataField',
            Value: title,
        },
        {
            $Type: 'UI.DataField',
            Value: system_ID,
        },
    ],
    UI.HeaderInfo                    : {
        TypeName      : '{i18n>extension}',
        TypeNamePlural: '{i18n>extensions}',
        Title         : {
            $Type: 'UI.DataField',
            Value: title,
        },
    },
    UI.Identification                : [
        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'DevelopmentService.clearDevelopmentObjectList',
            Label        : '{i18n>clearDevelopmentObjectList}',
            Determining  : true,
            ![@UI.Hidden]: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
        },
        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'DevelopmentService.addUnassignedDevelopmentObjects',
            Label        : '{i18n>addUnassignedDevelopmentObjects}',
            Determining  : true,
            ![@UI.Hidden]: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
        },
        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'DevelopmentService.addDevelopmentObjectsByDevClass',
            Label        : '{i18n>addDevelopmentObjectsByDevClass}',
            Determining  : true,
            ![@UI.Hidden]: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
        },
        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'DevelopmentService.addDevelopmentObject',
            Label        : '{i18n>addDevelopmentObject}',
            Determining  : true,
            ![@UI.Hidden]: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
        },
    ],
);

annotate service.Extensions with {
    system @(
        Common.ValueList: {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Systems',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: system_ID,
                    ValueListProperty: 'ID',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'sid',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'comment',
                },
            ],
        },
        Common.Text     : {
            $value                : system.sid,
            ![@UI.TextArrangement]: #TextOnly
        },
    )
};

annotate service.Extensions with {
    title  @Common.Label: '{i18n>title}';
    system @Common.Label: '{i18n>system}';
};

annotate service.DevelopmentObjects with @(UI.LineItem #developmentObjectList: [
    {
        $Type            : 'UI.DataField',
        Value            : devClass,
        ![@UI.Importance]: #High,
    },
    {
        $Type            : 'UI.DataField',
        Value            : namespace,
        ![@UI.Importance]: #Low,
    },
    {
        $Type            : 'UI.DataField',
        Value            : objectType,
        ![@UI.Importance]: #High,
    },

    {
        $Type            : 'UI.DataField',
        Value            : objectName,
        ![@UI.Importance]: #High,
    },
    {
        $Type            : 'UI.DataField',
        Value            : score,
        ![@UI.Importance]: #Medium,
    },
    {
        $Type            : 'UI.DataField',
        Value            : languageVersion_code,
        ![@UI.Importance]: #Medium,
    },

]);

annotate service.inDevClass {
    devClass @(
        Common.Label                   : '{i18n>devClass}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'DevClassValueList',
            Parameters    : [{
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: devClass,
                ValueListProperty: 'devClass'
            }],
            Label         : '{i18n>chooseDevClass}',
        },
        Common.ValueListWithFixedValues: false
    );
}

annotate service.inDevelopmentObject {
    objectType @(
        Common.Label                   : '{i18n>objectType}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'DevelopmentObjects',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: devClass,
                    ValueListProperty: 'devClass'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectName,
                    ValueListProperty: 'objectName'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectType,
                    ValueListProperty: 'objectType'
                }
            ],
            Label         : '{i18n>chooseObjectType}',
        },
        Common.ValueListWithFixedValues: false
    );
    objectName @(
        Common.Label                   : '{i18n>objectName}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'DevelopmentObjects',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: devClass,
                    ValueListProperty: 'devClass'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectName,
                    ValueListProperty: 'objectName'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectType,
                    ValueListProperty: 'objectType'
                }
            ],
            Label         : '{i18n>chooseObjectName}',
        },
        Common.ValueListWithFixedValues: false
    );
    devClass   @(
        Common.Label                   : '{i18n>devClass}',
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'DevelopmentObjects',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: devClass,
                    ValueListProperty: 'devClass'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectName,
                    ValueListProperty: 'objectName'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectType,
                    ValueListProperty: 'objectType'
                }
            ],
            Label         : '{i18n>chooseDevClass}',
        },
        Common.ValueListWithFixedValues: false
    );
}

// CRUD operations
annotate service.Extensions with @(
    UI.CreateHidden: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
    UI.UpdateHidden: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}},
    UI.DeleteHidden: {$edmJson: {$Path: '/DevelopmentService.EntityContainer/FeatureControl/isNotManager'}}
);
