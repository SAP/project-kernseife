using kernseife.db as db from '../db/schema';

service AnalyticsService @(requires: ['analyst']) {

    @Aggregation.CustomAggregate #score: 'Edm.Decimal'
    @readonly
    entity DevelopmentObjects            as
        select from db.DevelopmentObjects {
            @Common.ValueListWithFixedValues: false
            objectType,
            objectName,
            devClass,
            systemId,
            extension_ID,
            IFNULL(
                extension.title, 'Unassigned'
            ) as extension          : String,
            @Common.Text                    : {
                $value                : languageVersion_code,
                ![@UI.TextArrangement]: #TextOnly,
            }
            languageVersion,
            @Common.Text                    : {
                $value                : languageVersion_code,
                ![@UI.TextArrangement]: #TextOnly,
            }
            languageVersion_code,
            findingList,
            version_ID,
            namespace,
            @Analytics.Measure: true                     @Aggregation.default: #SUM
            score,
            @Analytics.Measure: true                     @Aggregation.default: #SUM
            @Common.Label     : '{i18n>cleanupPotential}'
            cleanupPotential,
            @Common.Label     : '{i18n>stableScore}'
            @Analytics.Measure: true                     @Aggregation.default: #SUM
            potentialScore          : Integer,
            @Common.Label     : '{i18n>potentialLevel}'  @Common.Text        : {
                $value                : potentialLevel,
                ![@UI.TextArrangement]: #TextOnly,
            }  potentialLevel       : String,
            cleanupPotentialPercent : Decimal(8, 2),
            @Common.Text                    : {
                $value                : level,
                ![@UI.TextArrangement]: #TextOnly,
            }
            level,
            @Analytics.Measure: true                     @Aggregation.default: #SUM
            1 as objectCount        : Integer,
        }


    @cds.redirection.target: false
    @readonly
    entity DevClasses                    as
        select from db.DevelopmentObjects {
            key systemId,
            key devClass,
                sum(score)                  as score            : Integer,
                max(level)                  as level            : String,
                @Common.Label: '{i18n>potentialLevel}'
                max(potentialLevel)         as potentialLevel   : String,
                count( * )                  as objectCount      : Integer,
                @Common.Label     : '{i18n>cleanupPotential}'
                @Analytics.Measure: false
                sum(score - potentialScore) as cleanupPotential : Integer,
                @Common.Label     : '{i18n>stableScore}'
                @Analytics.Measure: false
                sum(potentialScore)         as potentialScore   : Integer,
                avg(score)                  as averageScore     : Decimal(10, 3)
        }
        group by
            systemId,
            devClass;

    @readonly
    entity DevelopmentObjectFindings     as projection on db.DevelopmentObjectFindings;

    @readonly
    entity Classifications               as
        projection on db.Classifications {
            *,
            @Analytics.Measure: true  @Aggregation.default: #SUM
            @Common.Label     : '{i18n>objectCount}'
            1 as objectCount : Integer
        }
        excluding {
            developemtObjectList
        };

    entity ScoreHistory                  as
        select from db.HistoricDevelopmentObjects as h
        inner join db.DevelopmentObjectVersions as v
            on h.version_ID = v.ID
        {
            key v.systemId,
            key v.createdAt           : DateTime,
                sum(h.score) as score : Integer,
        }
        group by
            v.systemId,
            v.createdAt;

    entity ExemptionHistory              as
        projection on db.Exemptions {
            key exemptionId,
                systemId,
                lastChangedAt,
                @Analytics.Measure: true  @Aggregation.default: #SUM
                @Common.Label     : '{i18n>objectCount}'
                1 as objectCount : Integer
        }

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
    @cds.redirection.target: false
    entity ObjectTypeValueList           as projection on db.ObjectTypeValueList;


}
