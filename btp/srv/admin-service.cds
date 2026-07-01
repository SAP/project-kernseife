using kernseife.db as db from '../db/schema';
using {kernseife_btp as btp} from './external/kernseife_btp';

service AdminService @(requires: 'admin') {

    type inSystemBTP                  : {
        @UI.ParameterDefaultValue       : 'ALL'
        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>system}',
            ValueList: {
                CollectionPath: 'BTPSystems',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: systemId,
                        ValueListProperty: 'sid'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            },
        }) systemId : String;
    }

    type inSystem                     : {
        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>system}',
            ValueList: {
                CollectionPath: 'Systems',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: systemId,
                        ValueListProperty: 'sid'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            },
        }) systemId : String;
    }

    type inFileType {
        @Common.Label: '{i18n>file}'
        stream   : LargeBinary  @Core.MediaType: mimeType  @Core.ContentDisposition.Filename: fileName;
        mimeType : String       @Core.IsMediaType;
        fileName : String;
    };

    type inClassificationExportFormat {
        @(Common: {
            ValueListWithFixedValues: true,
            Label                   : '{i18n>classificationExportFormat}',
            ValueList               : {
                CollectionPath: 'ClassificationFormats',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: format,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            }
        })
        format : ClassificationFormats:code;
    };


    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action importMissingClassificationsBTP( @mandatory systemId: inSystemBTP:systemId, );

    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action importMissingClassificationsFile(file: inFileType not null);

    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action importFindingsFile( @mandatory systemId: inSystem:systemId, file: inFileType not null);

    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action importFindingsBTP( @mandatory systemId: inSystemBTP:systemId, );

    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action importExemptionsBTP( @mandatory systemId: inSystemBTP:systemId, );

    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action importClassifications( @mandatory file: inFileType not null, @Common.Label: '{i18n>overwriteExisting}' overwriteExisting: Boolean);

    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action exportClassificationsFile(format: inClassificationExportFormat:format,
                                     @UI.Hidden: {$edmJson: {$If: [
                                         {$Eq: [
                                             {$Path: 'format'},
                                             'SYSTEM'
                                         ]},
                                         false,
                                         true
                                     ]}}
                                     @Common.Label: '{i18n>useLegacy}' useLegacy: Boolean,
                                     @UI.Hidden: {$edmJson: {$If: [
                                         {$Eq: [
                                             {$Path: 'format'},
                                             'EXTERNAL'
                                         ]},
                                         false,
                                         true
                                     ]}}
                                     @Common.Label: '{i18n>dateFrom}' dateFrom: Timestamp);

    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Jobs'], })
    action exportClassificationsBTP( @mandatory systemId: inSystemBTP:systemId, );

    entity ReleaseStates                     as projection on db.ReleaseStates;
    entity ReleaseStateSuccessors            as projection on db.ReleaseStateSuccessors;

    entity Imports                           as projection on db.Imports;
    entity Exports                           as projection on db.Exports;

    entity JobTypes                          as projection on db.JobTypes;

    event Imported : { // Async API
        ID   : Imports:ID;
        type : Imports:type;
    }

    entity FileUpload                        as projection on db.FileUpload;

    entity Destinations                      as projection on db.Destinations;

    entity JobStatus                         as projection on db.JobStatus;

    entity SimplificationItems               as projection on db.SimplificationItems;

    entity Ratings                           as projection on db.Ratings;
    entity Frameworks                        as projection on db.Frameworks;
    entity FrameworkTypes                    as projection on db.FrameworkTypes;
    entity SuccessorClassifications          as projection on db.SuccessorClassifications;
    entity ReleaseInfo                       as projection on db.ReleaseInfo;
    entity ClassicInfo                       as projection on db.ClassicInfo;
    entity ReleaseLabel                      as projection on db.ReleaseLabel;
    entity ReleaseLevel                      as projection on db.ReleaseLevel;
    entity LanguageVersions                  as projection on db.LanguageVersions;
    entity Notes                             as projection on db.Notes;
    entity NoteClassifications               as projection on db.NoteClassifications;
    entity SuccessorTypes                    as projection on db.SuccessorTypes;

    entity Customers                         as projection on db.Customers;

    entity Projects                          as
        projection on btp.ZKNSF_I_PROJECTS {
            *
        };

    entity Systems                           as
        projection on db.Systems {
            *,
            virtual setupDone    : Boolean,
            virtual setupNotDone : Boolean,
            project              : Association to Projects
                                       on project.systemId = $self.sid //Not exactly correct, but we need an ON condition here
        }
        actions {
            action setupSystem();
            action triggerATCRun();
        };


    type inInitialData                : {
        configUrl : String;
    }

            @odata.draft.enabled
    entity Settings                          as projection on db.Settings
        actions {
            @Common.IsActionCritical: true
            @(Common.SideEffects: {TargetEntities: [
                'in/customerList',
                'in/systemList',
                'in/ratingList',
            ], })
            action createInitialData(configUrl: inInitialData:configUrl @UI.ParameterDefaultValue: 'https://raw.githubusercontent.com/SAP/project-kernseife/refs/heads/main/defaultSetup.json'

            );
        };

    entity Jobs                              as
        projection on db.Jobs {
            *,
            virtual hideImports : Boolean,
            virtual hideExports : Boolean,
        };

    type inExportSystemClassification : {
        legacy : Boolean;
    }


    @cds.redirection.target: false
    entity ObjectTypeValueList               as projection on db.ObjectTypeValueList;

    @cds.redirection.target: false
    entity AdoptionEffortValueList           as projection on db.AdoptionEffortValueList;

    @cds.redirection.target: false
    entity ObjectSubTypeValueList            as projection on db.ObjectSubTypeValueList;

    @cds.redirection.target: false
    entity NamespaceValueList                as projection on db.NamespaceValueList;

    @cds.redirection.target: false
    entity ApplicationComponentValueList     as projection on db.ApplicationComponentValueList;

    @cds.redirection.target: false
    entity SoftwareComponentValueList        as projection on db.SoftwareComponentValueList;

    @cds.redirection.target: false
    entity DevClassValueList                 as projection on db.DevClassValueList;

    @cds.redirection.target: false
    entity RatingsValueList                  as projection on db.RatingsValueList;

    @cds.redirection.target: false
    entity NoteClassificationsValueList      as projection on db.NoteClassificationsValueList;

    @cds.redirection.target: false
    entity SuccessorClassificationsValueList as projection on db.SuccessorClassificationsValueList;


    entity ClassificationFormats             as projection on db.ClassificationFormats;

    entity ObjectTypes                       as projection on db.ObjectTypes;
    entity Criticality                       as projection on db.Criticality;

    @cds.redirection.target: false
    entity BTPSystems                        as projection on db.Systems
                                                where
                                                        destination != null
                                                    and destination != '';

}
