using AdminService as service from '../../srv/admin-service';

annotate service.Settings with @(
    UI.DeleteHidden                  : true,
    UI.HeaderInfo                    : {
        TypeName      : '{i18n>setting}',
        TypeNamePlural: '{i18n>settings}',
    },
    UI.FieldGroup #generalInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: modifiedBy,
            },
            {
                $Type: 'UI.DataField',
                Value: modifiedAt,
            },
            {
                $Type: 'UI.DataField',
                Value: createdBy,
            },
            {
                $Type: 'UI.DataField',
                Value: createdAt,
            }
        ],
    },
    UI.FieldGroup #setup             : {
        $Type: 'UI.FieldGroupType',
        Data : [{
            $Type: 'UI.DataField',
            Value: initialDataUrl,
        }],
    },
    UI.Facets                        : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>generalInformation}',
            ID    : 'generalInformation',
            Target: '@UI.FieldGroup#generalInformation',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>setup}',
            ID    : 'setup',
            Target: '@UI.FieldGroup#setup',
        },
    ],
    UI.Identification                : [{
        $Type      : 'UI.DataFieldForAction',
        Action     : 'AdminService.createInitialData',
        Label      : '{i18n>createInitialData}',
        Criticality: #Negative,

    }, ],
);

annotate service.inInitialData with {
    @assert.format: '^[A-Z0-9]{3,4}$'
    prefix        @Common.Label: '{i18n>prefix}';
    contactPerson @Common.Label: '{i18n>contactPerson}';
    customerTitle @Common.Label: '{i18n>customerTitle}';
}


annotate service.Settings with {

    modifiedBy             @Common.Label: '{i18n>modifiedBy}';
    modifiedAt             @Common.Label: '{i18n>modifiedAt}';
    createdBy              @Common.Label: '{i18n>createdBy}';
    createdAt              @Common.Label: '{i18n>createdAt}';
    initialDataUrl         @Common.Label: '{i18n>initialDataUrl}';
};
