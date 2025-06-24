using kernseife.db as db from '../db/data-model';

service ImportsService @(requires: 'admin') {
    entity Imports     as projection on db.Imports;
    entity ImportTypes as projection on db.ImportTypes;

    event Imported : { // Async API
        ID   : Imports : ID;
        type : Imports : type;
    }

    entity FileUpload  as projection on db.FileUpload;
    entity Systems     as projection on db.Systems;
    entity Ratings     as projection on db.Ratings;
}
