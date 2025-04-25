using kernseife.db as db from '../db/data-model';


service ViewerService @(requires: [
    'viewer',
    'admin'
]) {

    @readonly
    entity ReleaseStates                 as projection on db.ReleaseStates;


    @readonly
    entity ReleaseStateSuccessors        as projection on db.ReleaseStateSuccessors;

    @cds.redirection.target: false
    @readonly
    entity DevClasses                    as
        select from db.DevelopmentObjects {
            key devClass,
                sum(score) as score : Integer,

        }
        group by
            devClass;


    @readonly
    entity DevelopmentObjects            as
        projection on db.DevelopmentObjects
        excluding {
            findingList
        }
        where
            latestScoringImportId != '';


    @readonly
    entity ScoringFindingsAggregated     as projection on db.ScoringFindingsAggregated;


    @readonly
    entity SimplificationItems           as projection on db.SimplificationItems;


    @readonly
    entity Classifications               as projection on db.Classifications;


    @readonly
    entity ClassificationSuccessors      as projection on db.ClassificationSuccessors;

    @readonly
    entity Ratings                       as projection on db.Ratings;

    @readonly
    entity Frameworks                    as projection on db.Frameworks;

    @readonly
    entity FrameworkTypes                as projection on db.FrameworkTypes;

    @readonly
    entity SuccessorClassifications      as projection on db.SuccessorClassifications;

    @readonly
    entity ReleaseInfo                   as projection on db.ReleaseInfo;

    @readonly
    entity ClassicInfo                   as projection on db.ClassicInfo;

    @readonly
    entity ReleaseLabel                  as projection on db.ReleaseLabel;

    @readonly
    entity ReleaseLevel                  as projection on db.ReleaseLevel;

    @readonly
    entity CleanCoreLevel                as projection on db.CleanCoreLevel;

    @readonly
    entity LanguageVersions              as projection on db.LanguageVersions;

    @readonly
    entity Notes                         as projection on db.Notes;

    @readonly
    entity NoteClassifications           as projection on db.NoteClassifications;

    @readonly
    entity SuccessorTypes                as projection on db.SuccessorTypes;

    @readonly
    entity CodeSnippets                  as projection on db.CodeSnippets;

    @readonly
    entity Customers                     as projection on db.Customers;

    @readonly
    entity Systems                       as projection on db.Systems;

    @readonly
    entity Extensions                    as projection on db.Extensions;

    @readonly
    entity Settings                      as projection on db.Settings;

    @readonly
    entity AdoptionEffort                as projection on db.AdoptionEffort;

    @readonly
    @cds.redirection.target: false
    entity ObjectTypeValueList           as projection on db.ObjectTypeValueList;

    @cds.redirection.target: false
    @readonly
    entity AdoptionEffortValueList       as projection on db.AdoptionEffortValueList;

    @cds.redirection.target: false
    @readonly
    entity ObjectSubTypeValueList        as projection on db.ObjectSubTypeValueList;

    @cds.redirection.target: false
    @readonly
    entity NamespaceValueList            as projection on db.NamespaceValueList;

    @cds.redirection.target: false
    @readonly
    entity ApplicationComponentValueList as projection on db.ApplicationComponentValueList;

    @cds.redirection.target: false
    @readonly
    entity SoftwareComponentValueList    as projection on db.SoftwareComponentValueList;

    @cds.redirection.target: false
    @readonly
    entity DevClassValueList             as projection on db.DevClassValueList;

    @readonly
    entity ObjectTypes                   as projection on db.ObjectTypes;

    @readonly
    entity Criticality                   as projection on db.Criticality;

    @readonly
    entity Imports                       as projection on db.Imports;

    @readonly
    entity DevelopmentObjectsAggregated  as projection on db.DevelopmentObjectsAggregated;


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

}
