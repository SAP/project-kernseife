import {
  DevelopmentObject,
  Import,
  ScoringRecord
} from '#cds-models/kernseife/db';
import { db, entities, log, Transaction } from '@sap/cds';
import { text } from 'node:stream/consumers';
import papa from 'papaparse';

const LOG = log('DevelopmentObjectFeature');

export const determineCleanCoreLevel = async (
  developmentObject
): Promise<string> => {
  //LOG.info("determineCleanCoreLevel", { developmentObject });

  const result = await SELECT.from(entities.ScoringRecords)
    .columns(
      `releaseState.releaseLevel_code as releaseLevel`,
      `count(*) as count`
    )
    .where({
      import_ID: developmentObject.latestScoringImportId,
      objectType: developmentObject.objectType,
      objectName: developmentObject.objectName,
      devClass: developmentObject.devClass,
      systemId: developmentObject.systemId
    })
    .groupBy('releaseState.releaseLevel_code');

  if (!result || result.length === 0) {
    // Determine base Level without findings
    if (developmentObject.languageVersion_code === '5') return 'A';
    if (developmentObject.languageVersion_code === '2') return 'B';
    return 'C'; // May be B?
  }

  const totalFindings = result.reduce((sum, row) => {
    return sum + row.count;
  }, 0);

  // Number of Objects used per Release Level
  // Create a Map with the number of objects per release level
  const releaseLevelMap = new Map();
  // define map initial values
  releaseLevelMap.set('RELEASED', 0);
  releaseLevelMap.set('DEPRECATED', 0);
  releaseLevelMap.set('NOT_TO_BE_RELEASED', 0);
  releaseLevelMap.set('STABLE', 0);
  releaseLevelMap.set('CLASSIC', 0);
  releaseLevelMap.set('INTERNAL', 0);
  releaseLevelMap.set('NO_API', 0);
  releaseLevelMap.set('CONFLICT', 0);

  result.forEach((finding) => {
    const count = releaseLevelMap.get(finding.releaseLevel) || 0;
    releaseLevelMap.set(finding.releaseLevel, count + 1);
  });

  // Level A => only released objects
  if (releaseLevelMap.get('RELEASED') === totalFindings) {
    //TODO also check language Version?
    return 'A';
  }

  // Level B => only RELEASED and Classic objects
  if (
    releaseLevelMap.get('RELEASED') +
      releaseLevelMap.get('CLASSIC') +
      releaseLevelMap.get('STABLE') ===
    totalFindings
  ) {
    return 'B';
  }

  // Level C => only Released, Classic and Tier3 objects
  if (
    releaseLevelMap.get('RELEASED') +
      releaseLevelMap.get('CLASSIC') +
      releaseLevelMap.get('STABLE') +
      releaseLevelMap.get('INTERNAL') ===
    totalFindings
  ) {
    return 'C';
  }

  // Level C => no "not to be used objects"
  if (
    releaseLevelMap.get('NOT_TO_BE_RELEASED') === 0 &&
    releaseLevelMap.get('NO_API') === 0
  ) {
    return 'C';
  }

  // Baseline Level D
  return 'D';
};

export const getDevelopmentObjectCount = async () => {
  const result = await SELECT.from(entities.DevelopmentObjects).columns(
    'IFNULL(COUNT( * ),0) as count'
  );
  return result[0]['count'];
};

export const getDevelopmentObjectColumnsForCleanCoreLevel = (d) => {
  d.latestScoringImportId,
    d.objectType,
    d.objectName,
    d.systemId,
    d.devClass,
    d.languageVersion_code;
};

export const getTotalScore = async () => {
  const result = await SELECT.from(entities.DevelopmentObjects).columns(
    'IFNULL(SUM( score ), 0) as score'
  );
  return result[0]['score'];
};

export const determineNamespace = (developmentObject) => {
  switch (developmentObject.objectName?.charAt(0)) {
    case '/':
      return '/' + developmentObject.objectName.split('/')[1] + '/';
    case 'Z':
    case 'Y':
      return developmentObject.objectName?.charAt(0);
    default:
      return undefined;
  }
};

export const determineCleanCoreLevelByRef = async (ref) => {
  // read Development Object
  const developmentObject = await SELECT.one.from(ref);
  const cleanCoreLevel = await determineCleanCoreLevel(developmentObject);
  if (developmentObject.cleanCoreLevel_code !== cleanCoreLevel) {
    await await UPDATE.entity(
      entities.DevelopmentObjects,
      developmentObject.ID
    ).set({
      cleanCoreLevel_code: cleanCoreLevel
    });
  }
};

export const calculateCleanCoreScore = async (
  developmentObject
): Promise<number> => {
  // Get Latest Scoring Run
  const averageReleaseScore = await SELECT.from(entities.ScoringRecords)
    .columns('avg(classification.releaseLevel.score)')
    .where({
      import_ID: developmentObject.latestScoringImportId,
      objectType: developmentObject.objectType,
      objectName: developmentObject.objectName,
      devClass: developmentObject.devClass,
      systemId: developmentObject.systemId
    });
  if (
    !averageReleaseScore ||
    averageReleaseScore.length !== 1 ||
    !averageReleaseScore[0].avg
  )
    return 0;
  return averageReleaseScore[0].avg;
};

export const calculateScoreByRef = async (ref) => {
  // read Development Object
  const developmentObject = await SELECT.one.from(ref);

  // Get Latest Scoring Run
  const scoringRecordList = await SELECT.from(entities.ScoringRecords)
    .columns(
      'itemId',
      'rating_code',
      'classification.rating.code as rating_code_dyn',
      'classification.rating.score as score'
    )
    .where({
      import_ID: developmentObject.latestScoringImportId,
      objectType: developmentObject.objectType,
      objectName: developmentObject.objectName,
      devClass: developmentObject.devClass,
      systemId: developmentObject.systemId
    });
  LOG.info('scoringRecordList', { scoringRecordList: scoringRecordList });
  const score = scoringRecordList.reduce((sum, row) => {
    return sum + row.score;
  }, 0);
  developmentObject.score = score || 0;
  developmentObject.cleanCoreLevel_code =
    await determineCleanCoreLevel(developmentObject);
  developmentObject.cleanCoreScore =
    await calculateCleanCoreScore(developmentObject);
  LOG.info('Development Object Score', {
    score: developmentObject.score,
    cleanCoreLevel: developmentObject.cleanCoreLevel_code,
    cleanCoreScore: developmentObject.cleanCoreScore
  });
  // Update Development Object
  await UPSERT.into(entities.DevelopmentObjects).entries([developmentObject]);
  // Update Scoring Findings
  for (const scoringRecord of scoringRecordList) {
    if (scoringRecord.rating_code_dyn !== scoringRecord.rating_code) {
      //LOG.info("Updating Scoring Finding", { name: developmentObject.objectName, old: scoringRecord.rating_code, new: scoringRecord.rating_code_dyn });
      await UPDATE.entity(entities.ScoringRecords)
        .with({
          rating_code: scoringRecord.rating_code_dyn
        })
        .where({
          import_ID: developmentObject.latestScoringImportId,
          itemId: scoringRecord.itemId
        });
    }
  }

  return developmentObject;
};

export const calculateScoreAll = async () => {
  await db.run(
    'UPDATE kernseife_db_SCORINGRECORDS as s SET rating_code = (SELECT c.rating_code FROM kernseife_db_CLASSIFICATIONS as c WHERE c.objectType = s.refObjectType AND c.objectName = s.refObjectName AND c.applicationComponent = s.refApplicationComponent)'
  );

  await db.run(
    'UPDATE kernseife_db_DEVELOPMENTOBJECTS as d SET score = (' +
      'SELECT IFNULL(sum(r.score),0) AS sum_score ' +
      'FROM kernseife_db_SCORINGRECORDS as f ' +
      'INNER JOIN kernseife_db_RATINGS as r ON r.code = f.rating_code ' +
      'WHERE f.objectType = d.objectType AND f.objectName = d.objectName AND f.devClass = d.devClass AND f.systemId = d.systemId AND d.latestScoringImportId = f.import_ID ' +
      'GROUP BY f.import_ID, f.objectType, f.objectName, f.devClass, f.systemId)'
  );

  // Set Score to 0 in case there are no findings
  await db.run(
    "UPDATE kernseife_db_DEVELOPMENTOBJECTS as d SET score = 0 WHERE score IS NULL AND latestScoringImportId IS NOT NULL AND latestScoringImportId != ''"
  );

  LOG.info('Score Mass Calculation done');
};

export const determineNamespaceAll = async () => {
  await db.run(
    "UPDATE kernseife_db_DEVELOPMENTOBJECTS SET NAMESPACE = CASE SUBSTRING(OBJECTNAME,1,1) WHEN 'Z' THEN 'Z' WHEN 'Y' THEN 'Y' WHEN '/' THEN SUBSTR_REGEXPR('(^/.*/).+$' IN OBJECTNAME GROUP 1) ELSE ''  END"
  );
  LOG.info('Namespace Mass Determination done');
};

const calculateScore = async (developmentObject: DevelopmentObject) => {
  const result = await SELECT.from(entities.ScoringRecords)
    .columns(`sum(rating.score) as score`)
    .where({
      import_ID: developmentObject.latestScoringImportId,
      objectType: developmentObject.objectType,
      objectName: developmentObject.objectName,
      devClass: developmentObject.devClass
    })
    .groupBy('objectType', 'objectName', 'devClass');
  return result[0]?.score || 0;
};

export const getDevelopmentObjectIdentifier = (
  object: ScoringRecord | DevelopmentObject
) => {
  return (
    (object.systemId || '') +
    (object.devClass || '') +
    (object.objectType || '') +
    (object.objectName || '')
  );
};

export const getDevelopmentObjectMap = async () => {
  const developmentObjectDB = await SELECT.from(entities.DevelopmentObjects);
  return developmentObjectDB.reduce((map, developmentObject) => {
    return map.set(
      getDevelopmentObjectIdentifier(developmentObject),
      developmentObject
    );
  }, new Map<string, DevelopmentObject>()) as Map<string, DevelopmentObject>;
};

export const importScoring = async (
  scoringImport: Import,
  tx?: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  if (!scoringImport.file) throw new Error('File broken');

  const csv = await text(scoringImport.file);
  const result = papa.parse<any>(csv, {
    header: true,
    skipEmptyLines: true
  });
  const itemIdSet = new Set();

  const scoringRecordList = result.data
    .map((finding) => {
      if (itemIdSet.has(finding.itemId || finding.ITEMID || finding.itemID)) {
        // duplicate!
        throw new Error(
          'Duplicate ItemId ' +
            (finding.itemId || finding.ITEMID || finding.itemID)
        );
      }

      itemIdSet.add(finding.itemId || finding.ITEMID || finding.itemID);
      return {
        // Map Attribues
        itemId: finding.itemId || finding.ITEMID || finding.itemID,
        objectType: finding.objectType || finding.OBJECTTYPE,
        objectName: finding.objectName || finding.OBJECTNAME,
        devClass: finding.devClass || finding.DEVCLASS,
        refObjectType: finding.refObjectType || finding.REFOBJECTTYPE,
        refObjectName: finding.refObjectName || finding.REFOBJECTNAME,
        refApplicationComponent:
          finding.refApplicationComponent || finding.REFAPPLICATIONCOMPONENT,
        rating_code:
          finding.rating ||
          finding.RATING ||
          finding.ratingCode ||
          finding.RATINGCODE
      } as ScoringRecord;
    })
    .filter((finding) => {
      if (!finding.objectType || !finding.objectName) {
        LOG.warn('Invalid finding', { finding });
        return false;
      }
      return true;
    });

  if (scoringRecordList == null || scoringRecordList.length == 0) {
    LOG.info('No Records to import');
    return;
  }

  LOG.info(`Importing Scoring Findings ${scoringRecordList.length}`);
  let upsertCount = 0;

  // Reset Latest Scoring Run Import for all Development Objects of this System, so we exclude objects, that don't have any Findings anymore
  await UPDATE(entities.DevelopmentObjects)
    .set({ latestScoringImportId: '' })
    .where({ systemId: scoringImport.systemId });

  const developmentObjectMap = await getDevelopmentObjectMap();
  let progressCount = 0;
  const chunkSize = 1000;
  for (let i = 0; i < scoringRecordList.length; i += chunkSize) {
    LOG.info(
      `Processing ${i} to ${i + chunkSize} (${scoringRecordList.length}`
    );
    const chunk = scoringRecordList.slice(i, i + chunkSize);

    const developmentObjectUpsert = [] as Partial<DevelopmentObject>[];
    for (const scoringRecord of chunk) {
      progressCount++;
      // Try to find a Development Object
      const key = getDevelopmentObjectIdentifier(scoringRecord);
      const developmentObjectDB = developmentObjectMap.get(key);
      if (!developmentObjectDB) {
        // Create a new Development Object
        const developmentObject = {
          objectType: scoringRecord.objectType || '',
          objectName: scoringRecord.objectName,
          systemId: scoringRecord.systemId || '',
          devClass: scoringRecord.devClass || '',
          latestScoringImportId: scoringImport.ID,
          languageVersion_code: 'X', // Default
          namespace: ''
        } as DevelopmentObject;

        developmentObject.score = await calculateScore(developmentObject);

        developmentObject.namespace = determineNamespace(developmentObject);
        developmentObject.cleanCoreLevel_code =
          await determineCleanCoreLevel(developmentObject);
        developmentObject.cleanCoreScore =
          await calculateCleanCoreScore(developmentObject);

        if (
          !developmentObject.devClass ||
          !developmentObject.objectName ||
          !developmentObject.objectType ||
          !developmentObject.systemId
        ) {
          LOG.error('Invalid Development Object', { developmentObject });
        }
        developmentObjectUpsert.push(developmentObject);
        const diffKey = getDevelopmentObjectIdentifier(developmentObject);
        if (diffKey !== key) {
          LOG.error('Key mismatch', { key: key, diffKey: diffKey });
        }
        developmentObjectMap.set(key, developmentObject);
        upsertCount++;
      } else {
        if (developmentObjectDB.latestScoringImportId !== scoringImport.ID) {
          developmentObjectDB.latestScoringImportId = scoringImport.ID;

          // Update the score
          if (
            !developmentObjectDB.devClass ||
            !developmentObjectDB.objectName ||
            !developmentObjectDB.objectType ||
            !developmentObjectDB.systemId
          ) {
            LOG.error('Invalid Development Object', { developmentObjectDB });
          }
          developmentObjectDB.score = await calculateScore(developmentObjectDB);
          developmentObjectDB.namespace =
            determineNamespace(developmentObjectDB);
          developmentObjectDB.cleanCoreScore =
            await calculateCleanCoreScore(developmentObjectDB);
          developmentObjectDB.cleanCoreLevel_code =
            await determineCleanCoreLevel(developmentObjectDB);

          developmentObjectUpsert.push(developmentObjectDB);
          upsertCount++;
        } else {
          LOG.debug('Development Object already scored', {
            developmentObjectDB
          });
        }
      }
    }
    if (developmentObjectUpsert.length > 0) {
      await UPSERT.into(entities.DevelopmentObjects).entries(
        developmentObjectUpsert
      );
      if (tx) {
        await tx.commit();
      }
    }
    if (updateProgress) await updateProgress(progressCount);
  }
  if (upsertCount > 0) {
    LOG.info(`Upserted ${upsertCount} new DevelopmentObject(s)`);
  }
};

export const importScoringById = async (
  scoringImportId,
  tx: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  const scoringRunImport = await SELECT.one
    .from(entities.Imports, (d) => {
      d.ID, d.status, d.title, d.filed, d.systemId;
    })
    .where({ ID: scoringImportId });
  await importScoring(scoringRunImport, tx, updateProgress);
};

export const importLanguageVersion = async (
  languageVersionImport: Import,
  tx?: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  if (!languageVersionImport.file) throw new Error('File broken');
  const csv = await text(languageVersionImport.file);
  const result = papa.parse<any>(csv, {
    header: true,
    skipEmptyLines: true
  });

  const languageVersionRecordList = result.data
    .map((finding) => {
      return {
        // Map Attribues
        objectType: finding.objectType || finding.OBJECTTYPE,
        objectName: finding.objectName || finding.OBJECTNAME,
        devClass: finding.devClass || finding.DEVCLASS,
        languageVersion_code:
          finding.languageVersion ||
          finding.LANGUAGEVERSION ||
          finding.LanguageVersion ||
          finding.languageversion,
        creationDate:
          finding.creationDate ||
          finding.CREATIONDATE ||
          finding.creationdate ||
          finding.CREATION_DATE
      };
    })
    .filter((finding) => {
      if (!finding.objectType || !finding.objectName) {
        LOG.warn('Invalid finding', { finding });
        return false;
      }
      return true;
    });

  if (
    languageVersionRecordList == null ||
    languageVersionRecordList.length == 0
  ) {
    LOG.info('No Language Versions to import');
    return;
  }

  LOG.info(`Importing Language Versions ${languageVersionRecordList.length}`);
  let upsertCount = 0;

  const developmentObjectMap = await getDevelopmentObjectMap();

  const chunkSize = 1000;
  for (let i = 0; i < languageVersionRecordList.length; i += chunkSize) {
    const chunk = languageVersionRecordList.slice(i, i + chunkSize);

    const developmentObjectUpsert = [] as DevelopmentObject[];
    for (const languageVersion of chunk) {
      // Try to find a Development Object
      const key = getDevelopmentObjectIdentifier(languageVersion);
      const developmentObjectDB = developmentObjectMap.get(key);
      if (!developmentObjectDB) {
        // Create a new Development Object
        const developmentObject = {
          objectType: languageVersion.objectType,
          objectName: languageVersion.objectName,
          systemId: languageVersionImport.systemId,
          devClass: languageVersion.devClass,
          languageVersion_code: languageVersion.languageVersion_code,
          score: 0
        } as DevelopmentObject;

        developmentObject.namespace = determineNamespace(developmentObject);
        developmentObject.cleanCoreLevel_code =
          await determineCleanCoreLevel(developmentObject);

        // Check if Key changed!
        const diffKey = getDevelopmentObjectIdentifier(developmentObject);
        if (diffKey !== key) {
          LOG.error('Key mismatch', { key: key, diffKey: diffKey });
        } else {
          developmentObjectUpsert.push(developmentObject);
          developmentObjectMap.set(key, developmentObject);
        }
        upsertCount++;
      } else if (
        developmentObjectDB.languageVersion_code !==
        languageVersion.languageVersion_code
      ) {
        LOG.error('Language Version changed for scored object', {
          developmentObjectDB
        });
        developmentObjectDB.languageVersion_code =
          languageVersion.languageVersion_code;
        developmentObjectDB.cleanCoreLevel_code =
          await determineCleanCoreLevel(developmentObjectDB);
        developmentObjectUpsert.push(developmentObjectDB);
        upsertCount++;
      }
    }
    if (developmentObjectUpsert.length > 0) {
      await UPSERT.into(entities.DevelopmentObjects).entries(
        developmentObjectUpsert
      );
      if (tx) tx.commit();
    }
  }
  if (upsertCount > 0) {
    LOG.info(`Upserted ${upsertCount} new DevelopmentObject(s)`);
  }
  if (updateProgress) await updateProgress(languageVersionRecordList.length);
};

export const importLanguageVersionById = async (
  languageVersionImportId,
  tx?: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  const languageVersionImport = await SELECT.one
    .from(entities.Imports, (l) => {
      l.ID, l.file, l.fileType, l.systemId;
    })
    .where({ ID: languageVersionImportId });
  await importLanguageVersion(languageVersionImport, tx, updateProgress);
};

export const calculateCleanCoreScoreAll = async () => {
  await db.run(
    'UPDATE kernseife_db_DEVELOPMENTOBJECTS as d SET cleanCoreScore = (' +
      'SELECT IFNULL(avg(rl.score),0) AS avgScore ' +
      'FROM kernseife_db_SCORINGRECORDS as f ' +
      'INNER JOIN kernseife_db_Classifications as c ON c.objectType = f.refObjectType AND c.objectName = f.refObjectName AND c.applicationComponent = f.refApplicationComponent ' +
      'INNER JOIN kernseife_db_ReleaseLevel as rl ON rl.code = c.releaseLevel_code ' +
      'WHERE f.objectType = d.objectType AND f.objectName = d.objectName AND f.devClass = d.devClass AND f.systemId = d.systemId AND d.latestScoringImportId = f.import_ID ' +
      'GROUP BY f.import_ID, f.objectType, f.objectName, f.devClass, f.systemId)'
  );

  // Set Score to 0 in case there are no findings
  await db.run(
    "UPDATE kernseife_db_DEVELOPMENTOBJECTS as d SET cleanCoreScore = 0 WHERE cleanCoreScore IS NULL AND latestScoringImportId IS NOT NULL AND latestScoringImportId != ''"
  );

  LOG.info('Score Mass Clean Core Calculation done');
};

export const determineCleanCoreLevelAll = async (
  tx: Transaction,
  updateProgress: (progress: number) => Promise<void>
) => {
  const developmentObjects = await SELECT.from(
    entities.DevelopmentObjects
  ).columns(getDevelopmentObjectColumnsForCleanCoreLevel);

  let progressCount = 0;
  const chunkSize = 50;
  for (let i = 0; i < developmentObjects.length; i += chunkSize) {
    LOG.info(
      `Processing ${i} to ${i + chunkSize} (${developmentObjects.length})`
    );
    const chunk = developmentObjects.slice(i, i + chunkSize);

    const updatePromises = [] as any[];
    for (const developmentObject of chunk) {
      progressCount++;
      const cleanCoreLevel = await determineCleanCoreLevel(developmentObject);
      LOG.info('Clean Core Level', { cleanCoreLevel, developmentObject });
      if (developmentObject.cleanCoreLevel_code !== cleanCoreLevel) {
        updatePromises.push(
          UPDATE.entity(entities.DevelopmentObjects)
            .set({ cleanCoreLevel_code: cleanCoreLevel })
            .where({
              objectType: developmentObject.objectType,
              objectName: developmentObject.objectName,
              devClass: developmentObject.devClass,
              systemId: developmentObject.systemId
            })
        );
      }
    }
    await Promise.all(updatePromises);
    if (updatePromises.length > 0 && tx) {
      await tx.commit();
    }
    if (updateProgress) await updateProgress(progressCount);

    LOG.info(`Updated ${updatePromises.length} Development Objects`);
  }
};
