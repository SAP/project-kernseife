namespace kernseife.db;

using {
    cuid,
    managed
} from '@sap/cds/common';

@cds.persistence.journal

entity DevelopmentObjects : managed {

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>objectType}',
            ValueList: {
                CollectionPath: 'ObjectTypeValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectType,
                    ValueListProperty: 'objectType'
                }]
            }
        })
    key objectType            : String;
    key objectName            : String;

        @readonly
        @(Common                        : {
            Label    : '{i18n>devClass}',
            ValueList: {
                CollectionPath: 'DevClassValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: devClass,
                    ValueListProperty: 'devClass'
                }]
            }
        })
    key devClass              : String;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>systemId}',
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
            }
        })
    key systemId              : String;
        system                : Association to Systems
                                    on system.sid = $self.systemId;

        @readonly
        extension_ID          : String;

        @readonly
        extension             : Association to Extensions
                                    on extension.ID = $self.extension_ID;


        @readonly
        cleanCoreLevel        : Association to CleanCoreLevel;

        @readonly
        cleanCoreScore        : Decimal(4, 2);

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>namespace}',
            ValueList: {
                CollectionPath: 'NamespaceValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: namespace,
                    ValueListProperty: 'namespace'
                }]
            }
        })
        namespace             : String;
        languageVersion       : Association to LanguageVersions
                                    on languageVersion.code = $self.languageVersion_code;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>languageVersion}',
            ValueList: {
                CollectionPath: 'LanguageVersions',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: languageVersion_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            }
        })
        languageVersion_code  : String;
        latestScoringImportId : String;
        findingList           : Association to many ScoringRecords
                                    on  findingList.objectType = $self.objectType
                                    and findingList.objectName = $self.objectName
                                    and findingList.devClass   = $self.devClass
                                    and findingList.systemId   = $self.systemId
                                    and findingList.import.ID  = $self.latestScoringImportId;

        findingListAggregated : Association to many ScoringFindingsAggregated
                                    on  findingListAggregated.objectType = $self.objectType
                                    and findingListAggregated.objectName = $self.objectName
                                    and findingListAggregated.devClass   = $self.devClass
                                    and findingListAggregated.systemId   = $self.systemId
                                    and findingListAggregated.importId   = $self.latestScoringImportId;


        score                 : Integer;


}

entity ScoringFindingsAggregated    as
    select from db.ScoringRecords as s
    inner join Ratings as r
        on s.rating_code = r.code
    inner join db.DevelopmentObjects as d
        on  s.objectType = d.objectType
        and s.objectName = d.objectName
        and s.devClass   = d.devClass
        and s.systemId   = d.systemId
        and s.import.ID  = d.latestScoringImportId
    {
        key s.import.ID          as importId,
        key s.objectType,
        key s.objectName,
        key s.devClass,
        key s.systemId,
        key s.refObjectName,
        key s.refObjectType,
        key s.refApplicationComponent,
            s.rating_code        as code,
            r.score              as score,
            r.criticality        as criticality,
            count( * )           as count           : Integer,
            count( * ) * r.score as total           : Integer,
            @Measures.Unit: '%'
            round(
                (
                    100.0 / d.score
                ) * count( * ) * r.score, 2
            )                    as totalPercentage : Decimal(5, 2)
    }
    group by
        s.import.ID,
        s.objectType,
        s.objectName,
        s.devClass,
        s.systemId,
        s.refObjectName,
        s.refObjectType,
        s.refApplicationComponent,
        s.rating_code,
        r.score,
        d.score,
        r.criticality;


@cds.persistence.journal
entity ReleaseStates : cuid {
    tadirObjectType         : String;
    tadirObjectName         : String;
    objectType              : String;
    objectName              : String;
    softwareComponent       : String;
    applicationComponent    : String;
    releaseInfo             : Association to ReleaseInfo;
    classicInfo             : Association to ClassicInfo;
    releaseLevel            : Association to ReleaseLevel;
    successorClassification : Association to SuccessorClassifications;
    successorConceptName    : String;
    successorList           : Composition of many ReleaseStateSuccessors
                                  on successorList.releaseState = $self;
    labelList               : many String;
}

@cds.persistence.journal
entity ReleaseStateSuccessors : cuid {
    releaseState    : Association to ReleaseStates;
    tadirObjectType : String;
    tadirObjectName : String;
    objectType      : String;
    objectName      : String;
}


@cds.persistence.journal
entity Classifications : managed {
    key tadirObjectType             : String;
    key tadirObjectName             : String;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>objectType}',
            ValueList: {
                CollectionPath: 'ObjectTypeValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectType,
                    ValueListProperty: 'objectType'
                }]
            }
        })
    key objectType                  : String;
    key objectName                  : String;

        @(Common: {
            Label    : '{i18n>applicationComponent}',
            ValueList: {
                CollectionPath: 'ApplicationComponentValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: applicationComponent,
                    ValueListProperty: 'applicationComponent'
                }]
            }
        })
        applicationComponent        : String;


        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>objectType}',
            ValueList: {
                CollectionPath: 'ObjectSubTypeValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: subType,
                    ValueListProperty: 'subType'
                }]
            }
        })
        subType                     : String;

        @readonly
        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>softwareComponent}',
            ValueList: {
                CollectionPath: 'SoftwareComponentValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: softwareComponent,
                    ValueListProperty: 'softwareComponent'
                }]
            }
        })
        softwareComponent           : String;

        frameworkUsageList          : Composition of many FrameworkUsages
                                          on frameworkUsageList.classification = $self;

        adoptionEffort              : Association to AdoptionEffort
                                          on adoptionEffort.code = $self.adoptionEffort_code;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>adoptionEffort}',
            ValueList: {
                CollectionPath: 'AdoptionEffortValueList',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: adoptionEffort_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            }
        })
        adoptionEffort_code         : type of AdoptionEffort : code;
        comment                     : String;

        @readonly
        referenceCount              : Integer;


        @Common.ValueListWithFixedValues: true
        @(Common                        : {Label: '{i18n>releaseLevel}'})
        @readonly
        releaseLevel                : Association to ReleaseLevel;

        @readonly
        releaseState                : Association to ReleaseStates
                                          on  releaseState.tadirObjectType      = $self.tadirObjectType
                                          and releaseState.tadirObjectName      = $self.tadirObjectName
                                          and releaseState.objectType           = $self.objectType
                                          and releaseState.objectName           = $self.objectName
                                          and releaseState.applicationComponent = $self.applicationComponent;

        @(Common: {Label: '{i18n>numberOfSimplificationNotes}'})
        numberOfSimplificationNotes : Integer default 0;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>successorClassificationValueList}',
            ValueList: {
                CollectionPath: 'SuccessorClassificationsValueList',

                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: successorClassification_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'obsolete'
                    }
                ]
            }
        })
        successorClassification     : Association to SuccessorClassifications;

        successorList               : Composition of many ClassificationSuccessors
                                          on successorList.classification = $self;

        noteList                    : Composition of many Notes
                                          on noteList.classification = $self;


        rating                      : Association to Ratings
                                          on rating.code = $self.rating_code;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>rating}',
            ValueList: {
                CollectionPath: 'RatingsValueList',

                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: rating_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'score'
                    }
                ]
            }
        })
        rating_code                 : type of Ratings : code;

        codeSnippets                : Composition of many CodeSnippets
                                          on codeSnippets.classification = $self;

        @(Common                        : {Label: '{i18n>totalScore}'})
        @readonly
        totalScore                  : Integer;
        developmentObjectList       : Association to many DevelopmentObjectsAggregated
                                          on  developmentObjectList.refObjectType           = $self.objectType
                                          and developmentObjectList.refObjectName           = $self.objectName
                                          and developmentObjectList.refApplicationComponent = $self.applicationComponent;

}

@cds.persistence.journal
entity CodeSnippets : cuid {
    classification : Association to Classifications;

    @mandatory
    title          : String;
    comment        : String;
    coding         : String;
}

@cds.persistence.journal
entity Notes : cuid {
    classification          : Association to Classifications;

    @mandatory
    note                    : String;
    title                   : String;


    noteClassification      : Association to NoteClassifications
                                  on noteClassification.code = $self.noteClassification_code;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>noteClassification}',
        ValueList: {
            CollectionPath: 'NoteClassificationsValueList',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: noteClassification_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    noteClassification_code : type of NoteClassifications : code;
}

@cds.persistence.journal
entity ClassificationSuccessors : cuid {
    classification     : Association to Classifications;
    tadirObjectType    : String;
    tadirObjectName    : String;
    objectType         : String;
    objectName         : String;

    successorType      : Association to SuccessorTypes
                             on successorType.code = $self.successorType_code;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>successorType}',
        ValueList: {
            CollectionPath: 'SuccessorTypes',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: successorType_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    successorType_code : type of SuccessorTypes : code;
}

@cds.persistence.journal
entity Imports : cuid, managed {
    type          : String;
    title         : String;
    status        : String;
    systemId      : String;
    comment       : String;
    defaultRating : String(3);
    system        : Association to Systems
                        on system.sid = $self.systemId;

    @Core.MediaType: fileType
    file          : LargeBinary;

    @Core.IsMediaType
    fileType      : String;
}

@cds.persistence.journal
entity ScoringRecords {
    key import                  : Association to Imports;
    key itemId                  : String;
        objectType              : String;
        objectName              : String;
        refObjectType           : String;
        refObjectName           : String;
        refApplicationComponent : String;
        devClass                : String;
        systemId                : String;
        releaseState            : Association to ReleaseStates
                                      on  releaseState.objectType           = $self.refObjectType
                                      and releaseState.objectName           = $self.refObjectName
                                      and releaseState.applicationComponent = $self.refApplicationComponent;
        developmentObject       : Association to DevelopmentObjects
                                      on  developmentObject.objectType = $self.objectType
                                      and developmentObject.objectName = $self.objectName
                                      and developmentObject.devClass   = $self.devClass;
        classification          : Association to Classifications
                                      on  classification.objectType           = $self.refObjectType
                                      and classification.objectName           = $self.refObjectName
                                      and classification.applicationComponent = $self.refApplicationComponent;
        rating                  : Association to Ratings
                                      on rating.code = $self.rating_code;
        rating_code             : String;
}

@cds.persistence.journal
entity SimplificationItems {
    key objectType        : String;
    key objectName        : String;
    key softwareComponent : String;
    key note              : String;
        title             : String;
        itemCount         : Integer;
}

@cds.persistence.journal
entity ObjectTypes {
    key objectType : String;
        title      : String;
        category   : String;
//TODO Language Version enabled? BTP enabled?
}

define view ObjectTypeValueList as
    select from Classifications distinct {
        key objectType
    };

define view ObjectSubTypeValueList as
    select from Classifications distinct {
        key subType
    };

define view NamespaceValueList as
    select from DevelopmentObjects distinct {
        key namespace
    };

define view SoftwareComponentValueList as
    select from Classifications distinct {
        key softwareComponent
    };

define view ApplicationComponentValueList as
    select from Classifications distinct {
        key applicationComponent
    };


define view DevClassValueList as
    select from DevelopmentObjects distinct {
        key devClass
    };

define view AdoptionEffortValueList as
    select from AdoptionEffort distinct {
        key code,
            title
    };

@cds.persistence.journal
entity Ratings : cuid, managed {
    @mandatory code        : String(3);
    @mandatory title       : String;
    @mandatory score       : Integer;

    @Common.ValueListWithFixedValues: true
    @mandatory criticality : Association to Criticality;

    legacyRatingList       : Composition of many LegacyRatings
                                 on legacyRatingList.rating = $self;
}

@cds.persistence.journal
entity LegacyRatings : cuid {
    rating       : Association to Ratings;
    legacyRating : String(10);
}

@cds.persistence.journal
entity Frameworks : cuid, managed {
    code               : String;
    title              : String;
    criticality        : Association to Criticality;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>frameworkType}',
        ValueList: {
            CollectionPath: 'FrameworkTypes',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: frameworkType_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                },
            ]
        }
    })
    @mandatory
    frameworkType_code : String;

    frameworkType      : Association to FrameworkTypes
                             on frameworkType.code = $self.frameworkType_code;
}


@cds.odata.valuelist
entity FrameworkTypes {
    key code  : String;
        title : String;
}

@cds.persistence.journal
entity FrameworkUsages : cuid {
    classification : Association to Classifications;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>framwwork}',
        ValueList: {
            CollectionPath: 'Frameworks',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: framework_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                },
            ]
        }
    })
    @mandatory
    framework_code : String;


    framework      : Association to Frameworks
                         on framework.code = $self.framework_code;
}

@cds.odata.valuelist
@cds.persistence.journal
entity SuccessorClassifications {
    key code        : String;

        @Common.Label: '{i18n>title}'
        title       : String;
        criticality : Association to Criticality;

        @Common.Label: '{i18n>obsolete}'
        obsolete    : Boolean default false;

        custom      : Boolean default true;
}

@cds.odata.valuelist
@cds.persistence.journal
entity NoteClassifications {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.odata.valuelist
entity SuccessorTypes {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.odata.valuelist
entity ClassicInfo {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}


@cds.odata.valuelist
entity ReleaseInfo {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.odata.valuelist
entity ReleaseLevel {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
        score       : Integer;
}

@cds.odata.valuelist
entity CleanCoreLevel {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.odata.valuelist
entity ReleaseLabel {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}


@cds.odata.valuelist
entity LanguageVersions {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}


@cds.persistence.journal
entity AdoptionEffort {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

            @cds.persistence.journal
entity DevelopmentObjectsAggregated as
    select from db.ScoringRecords as s
    inner join Ratings as r
        on s.rating_code = r.code
    inner join db.DevelopmentObjects as d
        on  s.objectType = d.objectType
        and s.objectName = d.objectName
        and s.devClass   = d.devClass
        and s.systemId   = d.systemId
        and s.import.ID  = d.latestScoringImportId
    {
        key s.refObjectName,
        key s.refObjectType,
        key s.refApplicationComponent,
        key s.objectName,
        key s.objectType,
            s.rating_code        as code,
            r.score              as score,
            r.criticality        as criticality,
            count( * )           as count           : Integer,
            count( * ) * r.score as total           : Integer,
            @Measures.Unit: '%'
            round(
                (
                    100.0 / d.score
                ) * count( * ) * r.score, 2
            )                    as totalPercentage : Decimal(5, 2)
    }
    group by
        s.refObjectName,
        s.refObjectType,
        s.refApplicationComponent,
        s.objectName,
        s.objectType,
        s.rating_code,
        r.score,
        d.score,
        r.criticality;


@cds.persistence.journal
entity Systems : cuid, managed {
    @mandatory
    sid         : String;

    @mandatory
    title       : String;
    comment     : String;

    customer    : Association to Customers
                      on customer.ID = $self.customer_ID;


    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>customer}',
        ValueList: {
            CollectionPath: 'Customers',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'comment'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: customer_ID,
                    ValueListProperty: 'ID'
                },
            ]
        }
    })
    customer_ID : type of Customers : ID;
}

@cds.persistence.journal
entity Customers : cuid, managed {
    @mandatory
    title      : String;
    contact    : String;

    @mandatory
    prefix     : String;

    systemList : Association to many Systems
                     on systemList.customer = $self;
}


@cds.persistence.journal
entity Extensions : cuid, managed {
    @mandatory
    title                : String;

    @mandatory
    system               : Association to Systems;

    @readonly
    cleanCoreLevel       : Association to CleanCoreLevel;

    developemtObjectList : Association to many DevelopmentObjects
                               on developemtObjectList.extension_ID = $self.ID;

}

@cds.persistence.journal
entity Settings : managed {
    key ID             : String(36);
        
}

@cds.persistence.journal
entity Jobs : cuid, managed {
    title           : String;
    status          : JobStatus;
    type            : String;
    progressCurrent : Integer;
    progressTotal   : Integer;
}

@assert.range
type JobStatus : String enum {
    NEW;
    RUNNING;
    ERROR;
    SUCCESS;
}

@assert.range
type JobType   : String enum {
    IMPORT_SCORING = 'IMPORT_SCORING';
    IMPORT_MISSING_CLASSIFICATION = 'IMPORT_MISSING_CLASSIFICATION';
    IMPORT_CLOUD_CLASSIFICATION = 'IMPORT_CLOUD_CLASSIFICATION';
    IMPORT_RELEASE_STATE = 'IMPORT_RELEASE_STATE';
}

@cds.odata.valuelist
entity Criticality {
    key code        : String;
        criticality : Integer;
        title       : String;
}

@cds.persistence.skip
@odata.singleton
entity FileUpload {
    @Core.MediaType: '*'
    file : LargeBinary;
};

@cds.persistence.journal
entity Modifications : cuid, managed {
    objectType   : String;
    objectName   : String;
    devClass     : String;
    systemId     : String;
    type         : Association to ModificationTypes
                       on type.code = $self.type_code;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>modificationType}',
        ValueList: {
            CollectionPath: 'ModificationTypes',

            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: type_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    type_code    : type of ModificationTypes : code;


    @readonly
    extension_ID : String;

    @readonly
    extension    : Association to Extensions
                       on extension.ID = $self.extension_ID;
}

@cds.odata.valuelist
entity ModificationTypes {
    key code        : String;
        criticality : Association to Criticality;
        title       : String;
}

@cds.persistence.journal
entity Enhancements : cuid, managed {
    objectType   : String;
    objectName   : String;
    devClass     : String;
    systemId     : String;

    @readonly
    extension_ID : String;

    @readonly
    extension    : Association to Extensions
                       on extension.ID = $self.extension_ID;
}


entity ImportTypes {
    key code          : String;
        title         : String;
        reqSystemId   : Boolean;
        defaultRating : Boolean;
        comment       : Boolean;
}
