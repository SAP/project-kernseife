using kernseife.db as db from '../db/schema';
using kernseife.types as types from '../db/types';

service DevelopmentService @(requires: ['development-viewer']) {

    // Actions
    @Common.IsActionCritical: true
    @(Common.SideEffects: {TargetEntities: ['/DevelopmentService.EntityContainer/DevelopmentObjects'], })
    action   recalculateAllScores @(requires: 'development-manager')();

    entity ReleaseStates                     as projection on db.ReleaseStates;
    entity ReleaseStateSuccessors            as projection on db.ReleaseStateSuccessors;

    @cds.redirection.target: false
    entity DevClasses                        as
        select from db.DevelopmentObjects {
            key devClass,
                sum(score) as score : Integer,

        }
        group by
            devClass;


    entity DevelopmentObjects @(restrict: [
        {grant: 'READ'},
        {
            grant: 'WRITE',
            to   : 'development-manager'
        }
    ])                                       as projection on db.DevelopmentObjects;

    entity DevelopmentObjectsFindings        as projection on db.DevelopmentObjectFindings;

    entity HistoricDevelopmentObjects        as
        projection on db.HistoricDevelopmentObjects {
            *,
            ROW_NUMBER() over(partition by objectType,
            objectName,
            systemId order by createdAt asc) as versionNumber : Integer
        }
        order by
            versionNumber desc;

    entity DevelopmentObjectUsages           as projection on db.DevelopmentObjectUsages;

    @readonly
    entity Classifications                   as projection on db.Classifications;

    @readonly
    entity FrameworkUsages                   as projection on db.FrameworkUsages;

    @readonly
    entity ClassificationSuccessors          as projection on db.ClassificationSuccessors;

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

    @readonly
    entity Systems                           as projection on db.Systems;

    type inDevClass          : {
        devClass : String;
    }

    type inDevelopmentObject : {
        objectType : String;
        objectName : String;
        devClass   : String;
    }

            @odata.draft.enabled
    entity Extensions                              @(restrict: [
        {grant: 'READ'},
        {
            grant: '*',
            to   : 'development-manager'
        }
    ])                                       as projection on db.Extensions
        actions {
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action clearDevelopmentObjectList      @(requires: 'development-manager')();
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action addDevelopmentObjectsByDevClass @(requires: 'development-manager')( @mandatory devClass: inDevClass:devClass);
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action addUnassignedDevelopmentObjects @(requires: 'development-manager')();
            @(Common.SideEffects: {TargetEntities: ['in/developemtObjectList'], })
            action addDevelopmentObject            @(requires: 'development-manager')(
            @mandatory objectType: inDevelopmentObject:objectType,
                                                                                      @mandatory objectName: inDevelopmentObject:objectName,
                                                                                      @mandatory devClass: inDevelopmentObject:devClass);
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

    entity AdoptionEffort                    as projection on db.AdoptionEffort;
    entity ObjectTypes                       as projection on db.ObjectTypes;
    entity Criticality                       as projection on db.Criticality;

    @odata.singleton
    entity FeatureControl {
        isManager    : Boolean;
        isNotManager : Boolean;
    }

    function getTileInfo(appName: String) returns types.DynamicAppLauncher;
}
