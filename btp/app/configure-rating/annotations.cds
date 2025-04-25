using AdminService as service from '../../srv/admin-service';
using from '../../db/data-model';


annotate AdminService.Ratings with @(UI: {
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
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>legacyRatings}',
            ID : 'legacy',
            Target : 'legacyRatingList/@UI.LineItem#legacy',
        },
    ],
    FieldGroup #General: {Data: [
        {
            Value: title,
            Label: '{i18n>title}',
        },
        {
            Value: code,
            Label: '{i18n>code}',
        },
        {
            Value: criticality_code,
            Label: '{i18n>criticality}'
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : score,
            Label                    : '{i18n>score}',
            Criticality              : criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
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

annotate service.Ratings with @(UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: code,
        Label: '{i18n>code}',
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
        $Type            : 'UI.DataField',
        Value            : score,
        Label            : '{i18n>score}',
        ![@UI.Importance]: #High,
    },
]);

annotate service.Ratings with @(UI.HeaderInfo: {
    TypeName      : '{i18n>rating}',
    TypeNamePlural: '{i18n>ratings}',
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
});
annotate service.LegacyRatings with @(
    UI.LineItem #legacy : [
        {
            $Type : 'UI.DataField',
            Value : legacyRating,
            Label : '{i18n>legacyRating}',
        },
    ]
);

