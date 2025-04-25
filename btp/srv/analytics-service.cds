using kernseife.db as db from '../db/data-model';

service AnalyticsService @(requires: [
    'viewer',
    'admin'
]) {


    @Aggregation.CustomAggregate #score: 'Edm.Decimal'
    @readonly
    entity DevelopmentObjects            as
        select from db.DevelopmentObjects {
            objectType,
            objectName,
            devClass,
            systemId,
            extension_ID,
            IFNULL(
                extension.title, 'Unassigned'
            ) as extension   : String,
            languageVersion,
            languageVersion_code,
            findingListAggregated,
            latestScoringImportId,
            cleanCoreLevel,
            namespace,
            @Analytics.Measure  : true
            @Aggregation.default: #AVG
            cleanCoreScore,
            @Analytics.Measure  : true  @Aggregation.default: #SUM
            score,
            @Analytics.Measure  : true  @Aggregation.default: #SUM
            1 as objectCount : Integer
        }
        where
            latestScoringImportId != '';

    @readonly
    entity ScoringFindingsAggregated     as projection on db.ScoringFindingsAggregated;

    @readonly
    entity Classifications               as
        projection on db.Classifications
        excluding {
            developemtObjectList
        };

    @readonly
    entity Ratings                       as projection on db.Ratings;

    @readonly
    entity LanguageVersions              as projection on db.LanguageVersions;

    @readonly
    entity NoteClassifications           as projection on db.NoteClassifications;

    @readonly
    entity AdoptionEffort                as projection on db.AdoptionEffort;

    @readonly
    entity ReleaseLevel                  as projection on db.ReleaseLevel;

    @readonly
    entity CleanCoreLevel                as projection on db.CleanCoreLevel;

    @readonly
    entity ReleaseStates                 as projection on db.ReleaseStates;

    @readonly
    entity SuccessorClassifications      as projection on db.SuccessorClassifications;

    @readonly
    entity SuccessorTypes                as projection on db.SuccessorTypes;

    @readonly
    entity Frameworks                    as projection on db.Frameworks;

    @readonly
    entity FrameworkTypes                as projection on db.FrameworkTypes;

    @readonly
    entity ClassicInfo                   as projection on db.ClassicInfo;

    @readonly
    entity ReleaseInfo                   as projection on db.ReleaseInfo;

    @readonly
    entity ReleaseLabel                  as projection on db.ReleaseLabel;

    @readonly
    entity Settings                      as projection on db.Settings;

    @readonly
    entity Criticality                   as projection on db.Criticality;

    @readonly
    entity Systems                       as projection on db.Systems;

    @readonly
    entity Customers                     as projection on db.Customers;

    @readonly
    entity Extensions                    as projection on db.Extensions;

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

    @odata.singleton
    @cds.persistence.skip
    entity Tiles {
        @(Core.MediaType: 'text/plain')
        totalScore : LargeBinary;
    }

    @readonly
    entity DevelopmentObjectsAggregated  as projection on db.DevelopmentObjectsAggregated;
}
