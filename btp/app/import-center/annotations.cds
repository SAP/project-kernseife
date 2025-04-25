using AdminService as service from '../../srv/admin-service';

annotate service.Imports with @(
    UI.LineItem                           : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>title}',
            Value            : title,
            ![@UI.Importance]: #High,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>status}',
            Value            : status,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>systemId}',
            Value            : systemId,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Value            : createdBy,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Value            : createdAt,
            ![@UI.Importance]: #Medium,
        }
    ],
    UI.SelectionPresentationVariant #table: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem', ],
            SortOrder     : [{
                $Type     : 'Common.SortOrderType',
                Property  : createdAt,
                Descending: true,
            }, ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
);

annotate service.Imports with @(UI.HeaderInfo: {
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
    },
    TypeName      : '{i18n>import}',
    TypeNamePlural: '{i18n>imports}',
});
