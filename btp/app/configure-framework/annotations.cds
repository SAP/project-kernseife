using AdminService as service from '../../srv/admin-service';


annotate AdminService.Frameworks with @(UI: {
    Facets             : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>generalInformation}',
            Target: '@UI.FieldGroup#General'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>admin}',
            Target: '@UI.FieldGroup#Admin'
        },
    ],
    FieldGroup #General: {Data: [
        {
            Value                  : title,
            ![@Common.FieldControl]: #Mandatory,
            Label                  : '{i18n>title}',

        },
        {
            Value                  : code,
            ![@Common.FieldControl]: #Mandatory,
            Label                  : '{i18n>code}',
        },
        {
            Value: criticality_code,
            Label: '{i18n>criticality}'
        },
        {
            Value: frameworkType_code,
            Label: '{i18n>frameworkType}'
        },
    ]},
    FieldGroup #Admin  : {Data: [
        {
            Value: createdBy,
            Label: '{i18n>createdBy}',
        },
        {
            Value: createdAt,
            Label: '{i18n>createdAt}',
        },
        {
            Value: modifiedBy,
            Label: '{i18n>modifiedBy}',
        },
        {
            Value: modifiedAt,
            Label: '{i18n>modifiedAt}',
        }
    ]}
});

annotate service.Frameworks with @(UI.LineItem: [
    {
        $Type                  : 'UI.DataField',
        Value                  : code,
        ![@Common.FieldControl]: #Mandatory,
        Label                  : '{i18n>code}',
    },
    {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
    {
        $Type: 'UI.DataField',
        Value: criticality_code,
        Label: '{i18n>criticality}',
    },
    {
        $Type: 'UI.DataField',
        Value: frameworkType.title,
        Label: '{i18n>frameworkType}',
    },
]);

annotate service.Frameworks with @(UI.HeaderInfo: {
    TypeName      : '{i18n>framework}',
    TypeNamePlural: '{i18n>frameworks}',
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
});
annotate service.Frameworks with {
    frameworkType_code @Common.Text : {
        $value : frameworkType.title,
        ![@UI.TextArrangement] : #TextOnly
    }
};

