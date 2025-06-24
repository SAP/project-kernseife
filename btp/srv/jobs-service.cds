using kernseife.db as db from '../db/data-model';

service JobsService @(requires: 'admin') {
    entity Jobs as projection on db.Jobs;
}
