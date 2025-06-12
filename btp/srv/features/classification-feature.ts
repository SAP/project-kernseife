import { Classification, Import, ReleaseState } from '#cds-models/kernseife/db';
import { Transaction, connect, db, entities, log, utils } from '@sap/cds';
import { text } from 'node:stream/consumers';
import papa from 'papaparse';
import {
  getReleaseStateKey,
  getReleaseStateMap,
  updateReleaseState
} from './releaseState-feature';
import {
  ClassificationImport,
  ClassificationKey,
  EnhancementImport
} from '../types/imports';
import { JobResult } from '../types/file';
import e from 'express';

const LOG = log('ClassificationFeature');

export const NO_CLASS = 'NOC';

export const STANDARD = 'STANDARD';
export const CUSTOM = 'CUSTOM';

export const mapSubTypeToType = (subType) => {
  switch (subType) {
    case 'INTTAB':
    case 'TRANSP':
    case 'VIEW':
    case 'APPEND':
      return 'TABL';
    default:
      return subType;
  }
};

export const getAllClassificationColumns = (c) => {
  c.tadirObjectType,
    c.tadirObjectName,
    c.objectType,
    c.objectName,
    c.softwareComponent,
    c.applicationComponent,
    c.subType,
    c.referenceCount,
    c.rating_code,
    c.releaseLevel_code,
    c.successorClassification_code,
    c.numberOfSimplificationNotes,
    c.adoptionEffort_code,
    c.comment,
    c.frameworkUsageList(),
    c.successorList(),
    c.noteList();
};

const getClassificationKey = (classification: ClassificationKey) => {
  return (
    (classification.tadirObjectType || '') +
    (classification.tadirObjectName || '') +
    (classification.objectType || '') +
    (classification.objectName || '')
  );
};

export const getClassificationState = (classification) => {
  switch (classification.releaseLevel_code) {
    case 'CLASSIC':
      return 'classicAPI';
    case 'NO_API':
      return 'noAPI';
    default:
      return 'internalAPI';
  }
};

const getClassificationMap = async () => {
  return (
    await SELECT.from(entities.Classifications, (c) => {
      c.tadirObjectType, c.tadirObjectName, c.objectType, c.objectName;
    })
  ).reduce((map, classification) => {
    const key = getClassificationKey(classification);
    map[key] = true;
    return map;
  }, {});
};

export const getClassificationCount = async () => {
  const result = await SELECT.from(entities.Classifications).columns(
    'COUNT( * ) as count'
  );
  return result[0]['count'];
};

export const getClassificationSet = async (): Promise<Set<string>> => {
  // Load all Classifications so we can check if they exist
  const classificationList = await SELECT.from(
    entities.Classifications
  ).columns('tadirObjectType', 'tadirObjectName', 'objectType', 'objectName');
  const classificationSet = await classificationList.reduce(
    (set, classification) => {
      set.add(getClassificationKey(classification));
      return set;
    },
    new Set<string>()
  );

  return classificationSet;
};

export const getClassificationRatingMap = async () => {
  // Load all Classifications so we can check if they exist
  const classificationList = await SELECT.from(
    entities.Classifications
  ).columns(
    'tadirObjectType',
    'tadirObjectName',
    'objectType',
    'objectName',
    'rating_code'
  );
  const classificationMap = await classificationList.reduce(
    (map, classification) => {
      map[getClassificationKey(classification)] = classification.rating_code;
      return map;
    },
    {}
  );

  return classificationMap;
};

export const updateSimplifications = async (classification: Classification) => {
  // Find Simplification Items for classification
  const simplificationItems = await SELECT.from(
    entities.SimplificationItems
  ).where({
    objectName: classification.objectName,
    objectType: classification.objectType
  });
  if (simplificationItems.length == 0) {
    return false;
  }

  // Simple Comparison
  //TODO more sophisticated comparison
  if (
    classification.noteList &&
    classification.noteList.length == simplificationItems.length
  ) {
    return false;
  }

  const notes = simplificationItems.map((simplificationItem) => ({
    ID: utils.uuid(),
    note: simplificationItem.note,
    title: simplificationItem.title,
    noteClassification_code: 'SIMPLIFICATION_DB',
    classification_objectType: classification.objectType,
    classification_objectName: classification.objectName
  }));

  await DELETE.from(entities.Notes).where({
    noteClassification_code: 'SIMPLIFICATION_DB',
    classification_objectName: classification.objectName,
    classification_objectType: classification.objectType
  });
  // await INSERT.into(entities.Notes).entries(notes);

  classification.noteList = notes;
  classification.numberOfSimplificationNotes = notes.length;

  return true;
};

export const updateTotalScoreAndReferenceCount = async (classification) => {
  const totalScoreResult = await SELECT.from(
    entities.DevelopmentObjectsAggregated
  )
    .columns(
      'IFNULL(SUM(total),0) as totalScore',
      'IFNULL(SUM(count), 0) as referenceCount'
    )
    .where({
      refObjectName: classification.objectName,
      refObjectType: classification.objectType
    })
    .groupBy('refObjectName', 'refObjectType');
  if (totalScoreResult && totalScoreResult.length == 1) {
    if (
      classification.totalScore != totalScoreResult[0].totalScore ||
      classification.referenceCount != totalScoreResult[0].referenceCount
    ) {
      classification.totalScore = totalScoreResult[0].totalScore;
      classification.referenceCount = totalScoreResult[0].referenceCount;
      return true;
    } else {
      return false;
    }
  }
  // Reset!
  classification.totalScore = 0;
  classification.referenceCount = 0;
  return true;
};

const determineRatingPrefix = (
  classification: Classification,
  suffix: string
) => {
  if (
    classification.applicationComponent == 'BC' ||
    classification.applicationComponent?.startsWith('BC-') ||
    classification.applicationComponent == 'CA' ||
    classification.applicationComponent?.startsWith('CA-') ||
    classification.softwareComponent == 'SAP_BASIS'
  ) {
    return 'FW' + suffix;
  } else {
    return 'BF' + suffix;
  }
};

const getDefaultRatingCode = (classification: Classification) => {
  switch (classification.releaseLevel_code) {
    case 'RELEASED':
      return determineRatingPrefix(classification, '0');
    case 'DEPRECATED':
      return determineRatingPrefix(classification, '9');
    case 'CLASSIC':
    case 'STABLE':
      return determineRatingPrefix(classification, '1');
    case 'INTERNAL':
    case 'NOT_TO_BE_RELEASED':
      return determineRatingPrefix(classification, '5');
    case 'NO_API':
      return determineRatingPrefix(classification, '9');
    default:
      return NO_CLASS;
  }
};

// Can't use the enum, cause CDS TS Support sucks!
export const convertCriticalityToMessageType = (criticality) => {
  switch (criticality) {
    case 0: // Neutral
      return 'I';
    case 1: // Red
      return 'E';
    case 2: // Orange
      return 'W';
    case 3: // Green
      return 'S';
    default:
      return 'X';
  }
};

export const importInitialClassification = async (csv: string) => {
  const tx = db.tx();
  const result = papa.parse<any>(csv, {
    header: true,
    skipEmptyLines: true
  });

  const classificationRecordList = result.data
    .map((classificationRecord) => ({
      // Map Attribues
      tadirObjectType:
        classificationRecord.tadirObjectType ||
        classificationRecord.TADIROBJECTTYPE ||
        classificationRecord.tadirobjecttype,
      tadirObjectName:
        classificationRecord.tadirObjectName ||
        classificationRecord.TADIROBJECTNAME ||
        classificationRecord.tadirobjectname,
      objectType:
        classificationRecord.objectType ||
        classificationRecord.OBJECTTYPE ||
        classificationRecord.objecttype,
      objectName:
        classificationRecord.objectName ||
        classificationRecord.OBJECTNAME ||
        classificationRecord.objectname,
      softwareComponent:
        classificationRecord.softwareComponent ||
        classificationRecord.SOFTWARECOMPONENT ||
        classificationRecord.softwarecomponent,
      applicationComponent:
        classificationRecord.applicationComponent ||
        classificationRecord.APPLICATIONCOMPONENT ||
        classificationRecord.applicationcomponent,
      subType: classificationRecord.subType || classificationRecord.SUBTYPE
    }))
    .filter((classificationRecord) => {
      if (
        !classificationRecord.tadirObjectType ||
        !classificationRecord.tadirObjectName ||
        !classificationRecord.objectType ||
        !classificationRecord.objectName ||
        !classificationRecord.subType ||
        !classificationRecord.applicationComponent ||
        !classificationRecord.softwareComponent
      ) {
        LOG.warn('Invalid ClassificationRecord', { classificationRecord });
        return false;
      }
      return true;
    });

  if (!classificationRecordList || classificationRecordList.length == 0) {
    throw new Error('No valid Classification Records Found');
  }

  // Get all ReleaseStates
  const releaseStateMap = await getReleaseStateMap();

  const chunkSize = 50;
  for (let i = 0; i < classificationRecordList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${classificationRecordList.length}`);
    const chunk = classificationRecordList.slice(i, i + chunkSize);
    const classificationInsert = [] as Classification[];

    for (const classificationRecord of chunk) {
      // Create a new Classification
      const classification = {
        objectType: classificationRecord.objectType,
        objectName: classificationRecord.objectName,
        tadirObjectType: classificationRecord.tadirObjectType,
        tadirObjectName: classificationRecord.tadirObjectName,
        applicationComponent: classificationRecord.applicationComponent,
        softwareComponent: classificationRecord.softwareComponent,
        subType: classificationRecord.subType
          ? classificationRecord.subType
          : classificationRecord.objectType,
        releaseLevel_code: 'undefined',
        successorClassification_code: 'undefined',
        referenceCount: 0,
        comment: ''
      } as Classification;

      updateReleaseState(classification, releaseStateMap);
      await updateSimplifications(classification);

      // Set default rating code
      classification.rating_code = getDefaultRatingCode(classification);

      classificationInsert.push(classification);
    }

    if (classificationInsert.length > 0) {
      await INSERT.into(entities.Classifications).entries(classificationInsert);
      await tx.commit();
    }
  }
};

export const importMissingClassifications = async (
  classificationImport: Import,
  tx?: Transaction,
  updateProgress?: (progress: number) => void
) => {
  // Parse File
  if (!classificationImport.file) throw new Error('File broken');
  const csv = await text(classificationImport.file);
  const result = papa.parse<any>(csv, {
    header: true,
    skipEmptyLines: true
  });

  const classificationRecordList = result.data
    .map((finding) => ({
      // Map Attribues
      tadirObjectType:
        finding.tadirObjectType ||
        finding.TADIROBJECTTYPE ||
        finding.tadirobjecttype,
      tadirObjectName:
        finding.tadirObjectName ||
        finding.TADIROBJECTNAME ||
        finding.tadirobjectname,
      objectType:
        finding.objectType || finding.OBJECTTYPE || finding.objecttype,
      objectName:
        finding.objectName || finding.OBJECTNAME || finding.objectname,
      softwareComponent:
        finding.softwareComponent ||
        finding.SOFTWARECOMPONENT ||
        finding.softwarecomponent,
      applicationComponent:
        finding.applicationComponent ||
        finding.APPLICATIONCOMPONENT ||
        finding.applicationcomponent,
      subType: finding.subType || finding.SUBTYPE
    }))
    .filter((finding) => {
      if (
        !finding.tadirObjectType ||
        !finding.tadirObjectName ||
        !finding.objectType ||
        !finding.objectName ||
        !finding.subType ||
        !finding.applicationComponent ||
        !finding.softwareComponent
      ) {
        LOG.warn('Invalid finding', { finding });
        return false;
      }
      return true;
    });

  if (!classificationRecordList || classificationRecordList.length == 0) {
    throw new Error('No valid Findings Found');
  }

  if (
    classificationRecordList == null ||
    classificationRecordList.length == 0
  ) {
    LOG.info('No Records to import');
    return;
  }

  // Get all releaseState
  const releaseStateMap = await getReleaseStateMap();

  LOG.info(
    `Importing Classification Records ${classificationRecordList.length}`
  );
  let insertCount = 0;
  let progressCount = 0;

  // Check to not insert the same object twice
  const classificationMap = await getClassificationRatingMap();

  const chunkSize = 100;
  for (let i = 0; i < classificationRecordList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${classificationRecordList.length}`);
    const chunk = classificationRecordList.slice(i, i + chunkSize);
    const classificationInsert = [] as Classification[];

    for (const classificationRecord of chunk) {
      progressCount++;
      const key = getClassificationKey(classificationRecord);
      if (!classificationMap[key]) {
        // Create a new Classification
        const classification = {
          objectType: classificationRecord.objectType,
          objectName: classificationRecord.objectName,
          tadirObjectType: classificationRecord.tadirObjectType,
          tadirObjectName: classificationRecord.tadirObjectName,
          applicationComponent: classificationRecord.applicationComponent,
          softwareComponent: classificationRecord.softwareComponent,
          subType: classificationRecord.subType
            ? classificationRecord.subType
            : classificationRecord.objectType,
          releaseLevel_code: 'undefined',
          successorClassification_code: 'undefined',
          referenceCount: 0,
          comment: classificationImport.comment || ''
        } as Classification;

        if (classification.subType == 'TABL') {
          classification.comment = 'SubType Wrong';
        }

        // Try to update States
        updateReleaseState(classification, releaseStateMap);

        // Try to update States
        await updateSimplifications(classification);
        // make sure deep insert doesn't create notes again
        classification.noteList = [];

        // Update Total Score
        //LOG.info("Update Total Score", classification);
        await updateTotalScoreAndReferenceCount(classification);

        // Set default rating code
        classification.rating_code =
          classificationImport.defaultRating ||
          getDefaultRatingCode(classification);

        classificationMap[key] = classification.rating_code;

        LOG.info('Insert Classification', classification);

        classificationInsert.push(classification);
        insertCount++;
      } else if (
        classificationImport.defaultRating != NO_CLASS ||
        classificationImport.comment
      ) {
        const updatePayload = {};
        if (classificationImport.defaultRating != NO_CLASS) {
          updatePayload['rating_code'] = classificationImport.defaultRating;
        }
        if (classificationImport.comment) {
          updatePayload['comment'] = classificationImport.comment;
        }

        // Update Rating
        await UPDATE.entity(entities.Classifications)
          .with(updatePayload)
          .where({
            tadirObjectType: classificationRecord.tadirObjectType,
            tadirObjectName: classificationRecord.tadirObjectName,
            objectType: classificationRecord.objectType,
            objectName: classificationRecord.objectName
          });
        if (tx) {
          await tx.commit();
        }
      }
    }

    if (classificationInsert.length > 0) {
      await INSERT.into(entities.Classifications).entries(classificationInsert);
      if (tx) {
        await tx.commit();
      }
    }

    if (updateProgress) {
      await updateProgress(
        Math.round((100 / classificationRecordList.length) * progressCount)
      );
    }
  }

  if (insertCount > 0) {
    LOG.info(`Inserted ${insertCount} new Classification(s)`);
  }
  if (updateProgress) {
    await updateProgress(100);
  }
};

const getCommentForEnhancementObjectType = (
  enhancementObject: EnhancementImport
) => {
  if (enhancementObject.internalUse) {
    return 'Internal Use BADI';
  } else if (enhancementObject.singleUse) {
    return 'Single Use BADI';
  } else {
    return 'Multi Use BADI';
  }
};

const getEnhancementRatingCode = (
  enhancementObject: EnhancementImport,
  releaseState?: ReleaseState
) => {
  if (releaseState && releaseState.releaseLevel_code == 'RELEASED') {
    return 'EF0';
  }
  if (enhancementObject.internalUse) {
    return 'EF9';
  } else if (enhancementObject.singleUse) {
    return 'EF5';
  }
  return 'EF1';
};

export const importEnhancementObjects = async (
  enhancementImport: Import,
  tx?: Transaction,
  updateProgress?: (progress: number) => void
): Promise<JobResult> => {
  // Parse File
  if (!enhancementImport.file) throw new Error('File broken');

  const csv = await text(enhancementImport.file);
  const result = papa.parse<any>(csv, {
    header: true,
    skipEmptyLines: true
  });

  const enhancementObjectList = result.data as EnhancementImport[];

  // Get all releaseState
  const releaseStateMap = await getReleaseStateMap();

  LOG.info(`Importing Enhancement Objects ${enhancementObjectList.length}`);
  let insertCount = 0;
  let progressCount = 0;

  // Check to not insert the same object twice
  const classificationMap = await getClassificationRatingMap();

  const importLog: any[] = [];

  const chunkSize = 100;
  for (let i = 0; i < enhancementObjectList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${enhancementObjectList.length}`);
    const chunk = enhancementObjectList.slice(i, i + chunkSize);
    const classificationInsert = [] as Classification[];

    for (const enhancementObject of chunk) {
      progressCount++;
      // For those objects tadir and normal keys are always the same
      enhancementObject.tadirObjectType = enhancementObject.objectType;
      enhancementObject.tadirObjectName = enhancementObject.objectName;

      // Set default rating code
      const releaseState = releaseStateMap.get(
        getReleaseStateKey(enhancementObject)
      );

      const key = getClassificationKey(enhancementObject);
      if (!classificationMap[key]) {
        // Create a new Classification
        const classification = {
          objectType: enhancementObject.objectType,
          objectName: enhancementObject.objectName,
          tadirObjectType: enhancementObject.tadirObjectType,
          tadirObjectName: enhancementObject.tadirObjectName,
          applicationComponent: enhancementObject.applicationComponent,
          softwareComponent: enhancementObject.softwareComponent,
          subType: enhancementObject.objectType,
          releaseLevel_code: 'undefined',
          successorClassification_code: 'undefined',
          referenceCount: 0,
          comment: getCommentForEnhancementObjectType(enhancementObject)
        } as Classification;

        // Try to update States
        updateReleaseState(classification, releaseStateMap);

        // Try to update States
        await updateSimplifications(classification);
        // make sure deep insert doesn't create notes again
        classification.noteList = [];

        // Update Total Score
        //LOG.info("Update Total Score", classification);
        await updateTotalScoreAndReferenceCount(classification);

        classification.rating_code = getEnhancementRatingCode(
          enhancementObject,
          releaseState
        );

        classificationMap[key] = classification.rating_code;

        importLog.push({
          operation: 'insert',
          ...enhancementObject,
          rating: classification.rating_code,
          comment: classification.comment
        });

        classificationInsert.push(classification);
        insertCount++;
      } else {
        const existingRatingCode = classificationMap[key];
        const newRatingCode = getEnhancementRatingCode(
          enhancementObject,
          releaseState
        );
        const newComment =
          getCommentForEnhancementObjectType(enhancementObject);

        if (
          parseInt(existingRatingCode.slice(2), 10) >=
          parseInt(newRatingCode.slice(2), 10)
        ) {
          importLog.push({
            operation: 'skipped',
            ...enhancementObject,
            rating: newRatingCode,
            oldRating: classificationMap[key],
            comment: newComment
          });
          continue;
        }
        // Update Rating
        await UPDATE.entity(entities.Classifications)
          .with({
            rating_code: newRatingCode,
            comment: newComment
          })
          .where({
            tadirObjectType: enhancementObject.tadirObjectType,
            tadirObjectName: enhancementObject.tadirObjectName,
            objectType: enhancementObject.objectType,
            objectName: enhancementObject.objectName
          });
        if (tx) {
          await tx.commit();
        }

        importLog.push({
          operation: 'update',
          ...enhancementObject,
          rating: newRatingCode,
          oldRating: classificationMap[key],
          comment: newComment
        });
      }
    }

    if (classificationInsert.length > 0) {
      await INSERT.into(entities.Classifications).entries(classificationInsert);
      if (tx) {
        await tx.commit();
      }
    }

    if (updateProgress) {
      await updateProgress(
        Math.round((100 / enhancementObjectList.length) * progressCount)
      );
    }
  }

  if (insertCount > 0) {
    LOG.info(`Inserted ${insertCount} new Classification(s)`);
  }
  if (updateProgress) {
    await updateProgress(100);
  }

  const file = papa.unparse(importLog);

  // Write to file
  return {
    file: Buffer.from(file, 'utf8'),
    fileName: 'importLog.csv',
    fileType: 'application/csv'
  } as JobResult;
};

export const importEnhancementObjectsById = async (
  enhancementImportId: string,
  tx: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  const enhancementImport = await SELECT.one
    .from(entities.Imports, (d) => {
      d.ID, d.status, d.title, d.file;
    })
    .where({ ID: enhancementImportId });
  return await importEnhancementObjects(enhancementImport, tx, updateProgress);
};

export const importMissingClassificationsById = async (
  missingClassificationsImportId: string,
  tx: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  const missingClassificationsImport = await SELECT.one
    .from(entities.Imports, (d) => {
      d.ID, d.status, d.title, d.file, d.defaultRating, d.comment;
    })
    .where({ ID: missingClassificationsImportId });
  return await importMissingClassifications(
    missingClassificationsImport,
    tx,
    updateProgress
  );
};

export const getClassificationJsonStandard = async () => {
  const classifications = await SELECT.from(entities.Classifications, (c) => {
    c.tadirObjectType,
      c.tadirObjectName,
      c.objectType,
      c.objectName,
      c.softwareComponent,
      c.applicationComponent,
      c.releaseLevel_code,
      c.releaseState((r) => r.labelList),
      c.successorList();
  }).where({ releaseLevel_code: { not: { in: ['RELEASED', 'DEPRECATED'] } } });
  const classificationJson = {
    formatVersion: '2',
    objectClassifications: classifications.map((classification) => ({
      tadirObject: classification.tadirObjectType,
      tadirObjName: classification.tadirObjectName,
      objectType: classification.objectType,
      objectKey: classification.objectName,
      softwareComponent: classification.softwareComponent,
      applicationComponent: classification.applicationComponent,
      state: getClassificationState(classification),
      labels:
        (classification.releaseState &&
          classification.releaseState.labelList) ||
        [],
      successors: classification.successorList.map((successor) => ({
        tadirObject: successor.tadirObjectType,
        tadirObjName: successor.tadirObjectName,
        objectType: successor.objectType,
        objectKey: successor.objectName
      }))
    }))
  };

  return classificationJson;
};

export const getClassificationJsonCustom = async () => {
  const ratings = await SELECT.from(entities.Ratings, (r) => {
    r.code, r.title, r.criticality_code.as('criticality'), r.score;
  });
  const classifications = await SELECT.from(entities.Classifications, (c) => {
    c.tadirObjectType,
      c.tadirObjectName,
      c.objectType,
      c.objectName,
      c.softwareComponent,
      c.applicationComponent,
      c.rating_code,
      c.releaseLevel_code,
      c.releaseState((r) => r.labelList),
      c.successorList();
  });
  const classificationJson = {
    formatVersion: '1',
    ratings: ratings.map((rating) => ({
      ...rating,
      score: String(rating.score) // As ABAP XSLT doesn't seem to support numbers
    })),

    objectClassifications: classifications.map((classification) => ({
      tadirObject: classification.tadirObjectType,
      tadirObjName: classification.tadirObjectName,
      objectType: classification.objectType,
      objectKey: classification.objectName,
      softwareComponent: classification.softwareComponent,
      applicationComponent: classification.applicationComponent,
      state: classification.rating_code,
      labels:
        classification.releaseState && classification.releaseState.labelList
          ? classification.releaseState.labelList
          : [],
      successors: classification.successorList.map((successor) => ({
        tadirObject: successor.tadirObjectType,
        tadirObjName: successor.tadirObjectName,
        objectType: successor.objectType,
        objectKey: successor.objectName
      }))
    }))
  };

  return classificationJson;
};
/**
 * JSON to transfer Classifications between Kernseife BTP Tenants
 * @returns
 */
export const getClassificationJsonCloud = async () => {
  const classifications = await SELECT.from(entities.Classifications, (c) => {
    c.tadirObjectType,
      c.tadirObjectName,
      c.objectType,
      c.objectName,
      c.subType,
      c.softwareComponent,
      c.applicationComponent,
      c.rating_code,
      c.releaseLevel_code,
      c.successorClassification_code,
      c.adoptionEffort_code,
      c.comment,
      c.numberOfSimplificationNotes,
      c.releaseState((r) => r.labelList),
      c.successorList(),
      c.noteList();
  });
  //TODO Include Code Samples?
  const classificationJson = {
    formatVersion: '1',
    objectClassifications: classifications.map(
      (classification) =>
        ({
          tadirObjectType: classification.tadirObjectType,
          tadirObjectName: classification.tadirObjectName,
          objectType: classification.objectType,
          objectName: classification.objectName,
          subType: classification.subType,
          comment: classification.comment,
          adoptionEffort: classification.adoptionEffort_code,
          softwareComponent: classification.softwareComponent,
          applicationComponent: classification.applicationComponent,
          rating: classification.rating_code,
          numberOfSimplificationNotes:
            classification.numberOfSimplificationNotes,
          labels:
            classification.releaseState && classification.releaseState.labelList
              ? classification.releaseState.labelList
              : [],
          noteList: classification.noteList
            ? classification.noteList.map((note) => ({
                note: note.note,
                title: note.title,
                classification: note.noteClassification_code
              }))
            : [],
          successorClassification: classification.successorClassification_code,
          successorList: classification.successorList.map((successor) => ({
            tadirObjectType: successor.tadirObjectType,
            tadirObjectName: successor.tadirObjectName,
            objectType: successor.objectType,
            objectName: successor.objectName,
            successorType: successor.successorType_code
          }))
        }) as ClassificationImport
    )
  };

  return classificationJson;
};

const getLegacyRatingMap = async () => {
  const ratingList = await SELECT.from(entities.Ratings, (c) => {
    c.code, c.legacyRatingList();
  });
  return ratingList.reduce((acc, rating) => {
    for (const legacyRating of rating.legacyRatingList) {
      acc[legacyRating.legacyRating] = rating.code;
    }
    return acc;
  }, {});
};

export const importCloudClassifications = async (
  classificationList: ClassificationImport[],
  tx: Transaction,
  updateProgress: (progress: number) => Promise<void>
) => {
  // Get all releaseState
  const releaseStateMap = await getReleaseStateMap();

  const legacyRatingMap = await getLegacyRatingMap();

  const classificationMap = await getClassificationMap();

  let progressCount = 0;
  LOG.error('Importing ' + classificationList.length + ' Classifications');
  const chunkSize = Math.min(classificationList.length, 25);
  for (let i = 0; i < classificationList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${classificationList.length}`);
    const chunk = classificationList.slice(i, i + chunkSize);

    const classificationInsert = [] as any[];

    for (const classificationImport of chunk) {
      progressCount++;
      const classificationKey = getClassificationKey(classificationImport);
      // Check if already exists
      if (!classificationMap[classificationKey]) {
        // Create a new Classification
        const classification = {
          objectType: classificationImport.objectType,
          objectName: classificationImport.objectName,
          tadirObjectType: classificationImport.tadirObjectType,
          tadirObjectName: classificationImport.tadirObjectName,
          applicationComponent: classificationImport.applicationComponent,
          softwareComponent: classificationImport.softwareComponent,
          subType: classificationImport.subType,
          releaseLevel_code: 'undefined',
          referenceCount: 0,
          adoptionEffort_code: classificationImport.adoptionEffort,
          comment: classificationImport.comment,
          rating_code: legacyRatingMap[classificationImport.rating] || NO_CLASS,
          noteList: classificationImport.noteList,
          numberOfSimplificationNotes:
            classificationImport.numberOfSimplificationNotes,
          successorClassification_code:
            classificationImport.successorClassification || 'STANDARD',
          frameworkUsageList: [],
          codeSnippets: [],
          successorList: classificationImport.successorList.map(
            (successor) => ({
              tadirObjectType: successor.tadirObjectType,
              tadirObjectName: successor.tadirObjectName,
              objectType: successor.objectType,
              objectName: successor.objectName,
              successorType_code: successor.successorType || 'STANDARD'
            })
          )
        } as Classification;

        // Try to update States
        updateReleaseState(classification, releaseStateMap);

        // Try to update States
        await updateSimplifications(classification);

        // Update Total Score
        await updateTotalScoreAndReferenceCount(classification);

        classificationInsert.push(classification);
      }
    }

    if (classificationInsert.length > 0) {
      await INSERT.into(entities.Classifications).entries(classificationInsert);
      await tx.commit();
      await updateProgress(progressCount);

      LOG.info(`Inserted ${classificationInsert.length} Classifications`);
    }
  }

  await updateProgress(progressCount);
};

const assignFramework = async (
  classification: Classification,
  code: string
) => {
  LOG.debug('classification', classification);
  classification.frameworkUsageList = [
    ...(classification.frameworkUsageList || []).filter(
      (usage) => usage.framework_code != code
    ),
    {
      ID: utils.uuid(),
      framework_code: code
    }
  ];

  await UPDATE(entities.Classifications).set(classification).where({
    tadirObjectType: classification.tadirObjectType,
    tadirObjectName: classification.tadirObjectName,
    objectName: classification.objectName,
    objectType: classification.objectType
  });
};

export const assignFrameworkByRef = async (ref, code: string) => {
  const classification = await SELECT.one
    .from(ref)
    .columns(getAllClassificationColumns);
  await assignFramework(classification, code);
  const updatedClassification = await SELECT.one
    .from(ref)
    .columns(getAllClassificationColumns);
  return updatedClassification;
};

const assignSuccessor = async (
  classification: Classification,
  tadirObjectType: string,
  tadirObjectName: string,
  objectType: string,
  objectName: string,
  successorType: string
) => {
  LOG.debug('classification', classification);

  classification.successorClassification_code =
    successorType == 'STANDARD' ? 'STANDARD' : 'CUSTOM';
  classification.successorList = [
    ...(classification.successorList || []).filter(
      (successor) =>
        successor.tadirObjectType == tadirObjectType &&
        successor.tadirObjectName == tadirObjectName
    ),
    {
      ID: utils.uuid(),
      tadirObjectType,
      tadirObjectName,
      objectType,
      objectName,
      successorType_code: successorType
    }
  ];

  await UPDATE(entities.Classifications).set(classification).where({
    tadirObjectType: classification.tadirObjectType,
    tadirObjectName: classification.tadirObjectName,
    objectName: classification.objectName,
    objectType: classification.objectType
  });
};

export const assignSuccessorByRef = async (
  ref,
  tadirObjectType: string,
  tadirObjectName: string,
  objectType: string,
  objectName: string,
  successorType: string
) => {
  const classification = await SELECT.one
    .from(ref)
    .columns(getAllClassificationColumns);
  await assignSuccessor(
    classification,
    tadirObjectType,
    tadirObjectName,
    objectType,
    objectName,
    successorType
  );
  const updatedClassification = await SELECT.one
    .from(ref)
    .columns(getAllClassificationColumns);
  return updatedClassification;
};

const determineSubType = async (
  objectType: string,
  objectName: string,
  objectMetadataApi: any
) => {
  if (!objectMetadataApi) return objectType;
  const { objectMetadata } = objectMetadataApi.entities;
  // Determine Subtype
  if (objectType == 'TABL') {
    try {
      const result = await objectMetadataApi.run(
        SELECT(objectMetadata).where({
          objectType: objectType,
          objectName: objectName
        })
      );
      if (result && result.length == 1) {
        return result[0].subType;
      } else {
        LOG.error("Can't find Metadata", { objectType, objectName });
      }
    } catch (ex) {
      LOG.error('Error connecting to API_OBJECT_METADATA', ex);
    }
  }
  return objectType;
};

export const getMissingClassifications = async () => {
  try {
    const objectMetadataApi = await connect.to('API_OBJECT_METADATA');

    const releaseStateMap = await getReleaseStateMap();
    const classificationSet = await getClassificationSet();
    const classificationList = [] as any[];

    LOG.info(`Classification Count: ${classificationSet.size}`);
    LOG.info(`ReleaseState Count: ${releaseStateMap.size}`);

    for (const [key, value] of releaseStateMap) {
      if (
        !value.objectName ||
        !value.objectType ||
        !value.tadirObjectType ||
        !value.tadirObjectName
      ) {
        LOG.warn('Invalid Classification', { value });
        continue;
      }
      if (!classificationSet.has(key)) {
        const subType = await determineSubType(
          value.objectType.length > 4
            ? value.tadirObjectType
            : value.objectType,
          value.objectType.length > 4
            ? value.tadirObjectName
            : value.objectName,
          objectMetadataApi
        );

        // Missing Classification
        classificationList.push({
          tadirObjectType: value.tadirObjectType,
          tadirObjectName: value.tadirObjectName,
          objectType: value.objectType,
          objectName: value.objectName,
          softwareComponent: value.softwareComponent,
          applicationComponent: value.applicationComponent,
          subType: subType
        });
      }
    }
    return classificationList;
  } catch (ex) {
    LOG.error('Error connecting to API_OBJECT_METADATA', ex);
    return [];
  }
};
