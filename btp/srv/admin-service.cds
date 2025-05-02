using kernseife.db as db from '../db/data-model';

service AdminService @(requires: 'admin') {

    entity ReleaseStates                 as projection on db.ReleaseStates;
    entity ReleaseStateSuccessors        as projection on db.ReleaseStateSuccessors;

    @cds.redirection.target: false
    entity DevClasses                    as
        select from db.DevelopmentObjects {
            key devClass,
                sum(score) as score : Integer,

        }
        group by
            devClass;


    entity DevelopmentObjects            as projection on db.DevelopmentObjects
                                            where
                                                latestScoringImportId != ''
        actions {
            @(Common.SideEffects: {TargetEntities: [
                '/AdminService.EntityContainer/DevelopmentObjects/findingListAggregated',
                'in/cleanCoreLevel',
            ], })
            action calculateScore() returns DevelopmentObjects;

            action removeFromExtension();
        }

    entity Imports                       as projection on db.Imports;

    entity ScoringRecords                as
        projection on db.ScoringRecords {
            *,
            developmentObject.latestScoringImportId as latestScoringimportId
        };

    entity ScoringFindingsAggregated     as projection on db.ScoringFindingsAggregated;
    entity SimplificationItems           as projection on db.SimplificationItems;

    type inFramework         : {
        code : String;
    }

    type inSuccessor         : {
        tadirObjectType : String;
        tadirObjectName : String;
        objectType      : String;
        objectName      : String;
        successorType   : String;
    }

            @odata.draft.enabled
            @odata.draft.bypass
    entity Classifications               as projection on db.Classifications
        actions {
            action cleanupClassification()                                                    returns Classifications;
            @(Common.SideEffects: {TargetEntities: ['in/frameworkUsageList'], })
            action assignFramework( @mandatory frameworkCode : inFramework   : code)          returns Classifications;
            @(Common.SideEffects: {TargetEntities: ['in/frameworkUsageList'], })
            action assignSuccessor( @mandatory tadirObjectType : inSuccessor : tadirObjectType,
                                    @mandatory tadirObjectName : inSuccessor : tadirObjectName,
                                    @mandatory objectType : inSuccessor      : objectType,
                                    @mandatory objectName : inSuccessor      : objectName,
                                    @mandatory successorType : inSuccessor   : successorType) returns Classifications;
        };

    entity FrameworkUsages               as projection on db.FrameworkUsages;
    entity ClassificationSuccessors      as projection on db.ClassificationSuccessors;

    @odata.draft.enabled
    entity Ratings                       as projection on db.Ratings;

    entity LegacyRatings                 as projection on db.LegacyRatings;

    @odata.draft.enabled
    entity Frameworks                    as projection on db.Frameworks;

    entity FrameworkTypes                as projection on db.FrameworkTypes;
    entity DevelopmentObjectsAggregated  as projection on db.DevelopmentObjectsAggregated;
    entity SuccessorClassifications      as projection on db.SuccessorClassifications;
    entity ReleaseInfo                   as projection on db.ReleaseInfo;
    entity ClassicInfo                   as projection on db.ClassicInfo;
    entity ReleaseLabel                  as projection on db.ReleaseLabel;
    entity ReleaseLevel                  as projection on db.ReleaseLevel;
    entity CleanCoreLevel                as projection on db.CleanCoreLevel;
    entity LanguageVersions              as projection on db.LanguageVersions;
    entity Notes                         as projection on db.Notes;
    entity NoteClassifications           as projection on db.NoteClassifications;
    entity SuccessorTypes                as projection on db.SuccessorTypes;

    @odata.draft.bypass
    entity CodeSnippets                  as projection on db.CodeSnippets;

    entity Customers                     as projection on db.Customers;

    @odata.draft.enabled
    entity Systems                       as projection on db.Systems;

    type inDevClass          : {
        devClass : String;
    }

    type inDevelopmentObject : {
        objectType : String;
        objectName : String;
        devClass   : String;
    }

            @odata.draft.enabled
    entity Extensions                    as projection on db.Extensions
        actions {
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action clearDevelopmentObjectList();
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action addDevelopmentObjectsByDevClass( @mandatory devClass : inDevClass : devClass);
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action addUnassignedDevelopmentObjects();
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action addDevelopmentObject(
            @mandatory objectType : inDevelopmentObject                              : objectType,
                                        @mandatory objectName : inDevelopmentObject  : objectName,
                                        @mandatory devClass : inDevelopmentObject    : devClass);
        }

    type inInitialData       : {
        customerTitle     : String(30);
        contactPerson     : String;
        prefix            : String(6);
        configUrl         : String;
        classificationUrl : String;
    }

            @odata.draft.enabled
    entity Settings                      as projection on db.Settings
        actions {
            @Common.IsActionCritical: true
            action createInitialData(
            @mandatory contactPerson : inInitialData                          : contactPerson,
                                     @mandatory prefix : inInitialData        : prefix,
                                     @mandatory customerTitle : inInitialData : customerTitle,
                                     configUrl : inInitialData                : configUrl @UI.ParameterDefaultValue: 'https://raw.githubusercontent.com/SAP/project-kernseife/refs/heads/main/defaultSetup.json',
                                     classificationUrl : inInitialData        : classificationUrl @UI.ParameterDefaultValue: 'https://raw.githubusercontent.com/SAP/project-kernseife/refs/heads/main/defaultClassification.csv'

            );
        };

    entity Jobs                          as projection on db.Jobs;

    // Actions
    @Common.IsActionCritical: true
    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/DevelopmentObjects'], })
    action calculateScoreAll();

    @Common.IsActionCritical: true
    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/DevelopmentObjects'], })
    action determineNamespaceAll();

    @Common.IsActionCritical: true
    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/DevelopmentObjects'], })
    action determineCleanCoreLevelAll();

    action loadReleaseState();

    @Common.IsActionCritical: true
    @(Common.SideEffects: {TargetEntities: ['/AdminService.EntityContainer/Classifications'], })
    action cleanupClassificationAll();

    @odata.singleton
    @cds.persistence.skip
    entity Downloads {
        @(Core.MediaType                 : 'application/json')
        @Core.ContentDisposition.Filename: 'classificationLegacy.json'
        @Core.ContentDisposition.Type    : 'inline'
        classificationLegacy   : LargeBinary;

        @(Core.MediaType                 : 'application/json')
        @Core.ContentDisposition.Filename: 'classificationStandardy.json'
        @Core.ContentDisposition.Type    : 'inline'
        classificationStandard : LargeBinary;

        @(Core.MediaType                 : 'application/json')
        @Core.ContentDisposition.Filename: 'classificationCustom.json'
        @Core.ContentDisposition.Type    : 'inline'
        classificationCustom   : LargeBinary;

        @(Core.MediaType                 : 'application/json')
        @Core.ContentDisposition.Filename: 'classificationCloud.json'
        @Core.ContentDisposition.Type    : 'inline'
        classificationCloud    : LargeBinary;

        @(Core.MediaType                 : 'application/json')
        @Core.ContentDisposition.Filename: 'missingClassifications.json'
        @Core.ContentDisposition.Type    : 'inline'
        missingClassifications : LargeBinary;
    }


    entity AdoptionEffort                as projection on db.AdoptionEffort;

    @cds.redirection.target: false
    entity ObjectTypeValueList           as projection on db.ObjectTypeValueList;

    @cds.redirection.target: false
    entity AdoptionEffortValueList       as projection on db.AdoptionEffortValueList;

    @cds.redirection.target: false
    entity ObjectSubTypeValueList        as projection on db.ObjectSubTypeValueList;

    @cds.redirection.target: false
    entity NamespaceValueList            as projection on db.NamespaceValueList;

    @cds.redirection.target: false
    entity ApplicationComponentValueList as projection on db.ApplicationComponentValueList;

    @cds.redirection.target: false
    entity SoftwareComponentValueList    as projection on db.SoftwareComponentValueList;

    @cds.redirection.target: false
    entity DevClassValueList             as projection on db.DevClassValueList;

    entity ObjectTypes                   as projection on db.ObjectTypes;
    entity Criticality                   as projection on db.Criticality;
    entity ImportTypes                   as projection on db.ImportTypes;


    @cds.redirection.target: false
    define view RatingsValueList as
        select from db.Ratings
        order by
            score desc,
            code  asc;

    @cds.redirection.target: false
    define view NoteClassificationsValueList as
        select from db.NoteClassifications
        order by
            code asc;

    @cds.redirection.target: false
    define view SuccessorClassificationsValueList as
        select from db.SuccessorClassifications
        order by
            title asc;


    event Imported : { // Async API
        ID   : Imports : ID;
        type : Imports : type;
    }

    entity FileUpload                    as projection on db.FileUpload;

}
