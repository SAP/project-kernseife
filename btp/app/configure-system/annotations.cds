using AdminService as service from '../../srv/admin-service';


annotate AdminService.Systems with @(UI: {
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
            Value: title,
            Label: '{i18n>title}',
        },
        {
            Value: sid,
            Label: '{i18n>sid}',
        },
        {
            Value: title,
            Label: '{i18n>title}'
        },
        {
            Value: customer_ID,
            Label: '{i18n>customer}'
        }
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

annotate service.Systems with @(UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: sid,
        Label: '{i18n>sid}',
    },
    {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
    {
        $Type: 'UI.DataField',
        Value: customer.title,
        Label: '{i18n>customer}',
    },
    {
        $Type: 'UI.DataField',
        Value: comment,
        Label: '{i18n>comment}',
    },
]);

annotate service.Systems with @(UI.HeaderInfo: {
    TypeName      : '{i18n>system}',
    TypeNamePlural: '{i18n>systems}',
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
});

annotate service.Systems with {
    customer_ID @Common.Text: {
        $value                : customer.title,
        ![@UI.TextArrangement]: #TextOnly
    }
};
