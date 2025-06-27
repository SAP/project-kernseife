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
  ClassificationImportLog,
  EnhancementImport
} from '../types/imports';
import JSZip from 'jszip';
import { JobResult } from '../types/file';
import { PassThrough } from 'node:stream';
import { streamToBuffer } from '../lib/files';

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

export const getClassificationRatingMap = async (): Promise<
  Map<string, string>
> => {
  // Load all Classifications so we can check if they exist
  const classificationList = (await SELECT.from(
    entities.Classifications
  ).columns(
    'tadirObjectType',
    'tadirObjectName',
    'objectType',
    'objectName',
    'rating_code'
  )) as {
    tadirObjectType: string;
    tadirObjectName: string;
    objectType: string;
    objectName: string;
    rating_code: string;
  }[];
  const classificationMap = classificationList.reduce((map, classification) => {
    map.set(getClassificationKey(classification), classification.rating_code);
    return map;
  }, new Map<string, string>());

  return classificationMap;
};

export const getClassificationRatingAndCommentMap = async (): Promise<
  Map<string, { rating_code: string; comment: string }>
> => {
  // Load all Classifications so we can check if they exist
  const classificationList = (await SELECT.from(
    entities.Classifications
  ).columns(
    'tadirObjectType',
    'tadirObjectName',
    'objectType',
    'objectName',
    'rating_code',
    'comment'
  )) as {
    tadirObjectType: string;
    tadirObjectName: string;
    objectType: string;
    objectName: string;
    rating_code: string;
    comment: string;
  }[];
  const classificationMap = classificationList.reduce((map, classification) => {
    map.set(getClassificationKey(classification), {
      rating_code: classification.rating_code,
      comment: classification.comment
    });
    return map;
  }, new Map<string, { rating_code: string; comment: string }>());

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
  const classificationRatingMap = await getClassificationRatingMap();

  const importLogList = [] as ClassificationImportLog[];

  const chunkSize = 100;
  for (let i = 0; i < classificationRecordList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${classificationRecordList.length}`);
    const chunk = classificationRecordList.slice(i, i + chunkSize);
    const classificationInsert = [] as Classification[];

    for (const classificationRecord of chunk) {
      progressCount++;
      const key = getClassificationKey(classificationRecord);
      if (!classificationRatingMap.has(key)) {
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

        // Add to Map to prevent double inserts
        classificationRatingMap.set(key, classification.rating_code);

        classificationInsert.push(classification);
        insertCount++;

        // Add to Import Log
        importLogList.push({
          tadirObjectType: classification.tadirObjectType,
          tadirObjectName: classification.tadirObjectName,
          objectType: classification.objectType,
          objectName: classification.objectName,
          status: 'NEW',
          oldRating: '',
          newRating: classification.rating_code
        } as ClassificationImportLog);
      } else if (
        classificationImport.defaultRating != NO_CLASS ||
        classificationImport.comment
      ) {
        const updatePayload = {} as { rating_code?: string; comment?: string };
        if (
          classificationImport.defaultRating &&
          classificationImport.defaultRating != NO_CLASS &&
          classificationRatingMap.get(key) != classificationImport.defaultRating
        ) {
          updatePayload['rating_code'] = classificationImport.defaultRating;
        }
        if (classificationImport.comment) {
          updatePayload['comment'] = classificationImport.comment;
        }

        // Update Rating
        if (updatePayload.rating_code || updatePayload.comment) {
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
          importLogList.push({
            tadirObjectType: classificationRecord.tadirObjectType,
            tadirObjectName: classificationRecord.tadirObjectName,
            objectType: classificationRecord.objectType,
            objectName: classificationRecord.objectName,
            status: 'UPDATED',
            oldRating: classificationRatingMap.get(key),
            newRating: updatePayload['rating_code']
          } as ClassificationImportLog);
        } else {
          importLogList.push({
            tadirObjectType: classificationRecord.tadirObjectType,
            tadirObjectName: classificationRecord.tadirObjectName,
            objectType: classificationRecord.objectType,
            objectName: classificationRecord.objectName,
            status: 'UNCHANGED',
            oldRating: classificationRatingMap.get(key),
            newRating: classificationRatingMap.get(key)
          } as ClassificationImportLog);
        }
      } else {
        importLogList.push({
          tadirObjectType: classificationRecord.tadirObjectType,
          tadirObjectName: classificationRecord.tadirObjectName,
          objectType: classificationRecord.objectType,
          objectName: classificationRecord.objectName,
          status: 'UNCHANGED',
          oldRating: classificationRatingMap.get(key),
          newRating: classificationRatingMap.get(key)
        } as ClassificationImportLog);
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
  const file = papa.unparse(importLogList);
  // Write to file
  return {
    file: Buffer.from(file, 'utf8'),
    fileName: 'importLog.csv',
    fileType: 'application/csv'
  } as JobResult;
};

const getCommentForEnhancementObjectType = (
  enhancementObject: EnhancementImport
): string => {
  if (enhancementObject.objectType == 'ENHS') {
    return 'Enhancement Spot';
  } else if (enhancementObject.objectType == 'SXSD') {
    return 'Classic BADI Definition'
  }
  if (enhancementObject.internalUse) {
    return 'SAP Internal BADI';
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
  } else if (
    releaseState &&
    (releaseState.releaseLevel_code == 'NOT_TO_BE_RELEASED' ||
      releaseState.releaseLevel_code == 'DEPRECATED') &&
    releaseState.successorList &&
    releaseState.successorList.length > 0
  ) {
    return 'EF9';
  } else if (releaseState && releaseState.releaseLevel_code == 'DEPRECATED') {
    return 'EF1'; //TODO this doesn't make sense, but.. yeah
  } else if (releaseState && releaseState.releaseLevel_code != 'undefined') {
    return 'MIG';
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
  const classificationMap = await getClassificationRatingAndCommentMap();
  const importLog: any[] = [];

  const chunkSize = 100;
  for (let i = 0; i < enhancementObjectList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${enhancementObjectList.length}`);
    const chunk = enhancementObjectList.slice(i, i + chunkSize);

    let transactionPending = false;
    for (const enhancementObject of chunk) {
      progressCount++;

      // Set default rating code
      const releaseState = releaseStateMap.get(
        getReleaseStateKey(enhancementObject)
      );

      const key = getClassificationKey(enhancementObject);
      if (!classificationMap.has(key)) {
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

        classificationMap.set(key, {
          rating_code: classification.rating_code,
          comment: classification.comment || ''
        });

        importLog.push({
          operation: 'insert',
          ...enhancementObject,
          rating: classification.rating_code,
          comment: classification.comment
        });

        await INSERT.into(entities.Classifications).entries([classification]);
        transactionPending = true;
        insertCount++;
      } else {
        const existingData = classificationMap.get(key)!; // We checked before that the key exists
        const existingRatingCode = existingData.rating_code;
        const existingComment = existingData.comment;
        const newRatingCode = getEnhancementRatingCode(
          enhancementObject,
          releaseState
        );

        const newComment =
          getCommentForEnhancementObjectType(enhancementObject);
        if (
          newRatingCode == existingRatingCode &&
          newComment == existingComment
        ) {
          importLog.push({
            operation: 'skipped',
            ...enhancementObject,
            rating: newRatingCode,
            oldRating: existingRatingCode,
            comment: newComment
          });
          continue;
        }

        classificationMap.set(key, {
          rating_code: newRatingCode,
          comment: newComment
        });

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
        transactionPending = true;

        importLog.push({
          operation: 'update',
          ...enhancementObject,
          rating: newRatingCode,
          oldRating: existingRatingCode,
          comment: newComment
        });
      }
    }

    if (transactionPending && tx) {
      await tx.commit();
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

const getRatingMap = async (): Promise<Map<string, string>> => {
  const ratingList = await SELECT.from(entities.Ratings, (c) => {
    c.code, c.legacyRatingList();
  });
  return ratingList.reduce((map, rating) => {
    for (const legacyRating of rating.legacyRatingList) {
      map.put(legacyRating.legacyRating, rating.code);
    }
    // also add the current Rating
    map.put(rating.code, rating.code);
    return map;
  }, new Map<string, string>());
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

const importClassification = async (
  classificationImport: ClassificationImport,
  classificationSet: Set<string>,
  releaseStateMap: Map<string, ReleaseState>,
  ratingMap: Map<string, string>
): Promise<ClassificationImportLog> => {
  // Check if Classification already exists
  const classificationKey = getClassificationKey(classificationImport);
  if (!classificationSet.has(classificationKey)) {
    // Add Classification
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
      rating_code: ratingMap.get(classificationImport.rating) || NO_CLASS,
      noteList: classificationImport.noteList,
      numberOfSimplificationNotes:
        classificationImport.numberOfSimplificationNotes,
      successorClassification_code:
        classificationImport.successorClassification || 'STANDARD',
      frameworkUsageList: [],
      codeSnippets: [],
      successorList: classificationImport.successorList.map((successor) => ({
        tadirObjectType: successor.tadirObjectType,
        tadirObjectName: successor.tadirObjectName,
        objectType: successor.objectType,
        objectName: successor.objectName,
        successorType_code: successor.successorType || 'STANDARD'
      }))
    } as Classification;

    // Try to update States
    updateReleaseState(classification, releaseStateMap);

    // Try to update States
    await updateSimplifications(classification);

    // Update Total Score
    await updateTotalScoreAndReferenceCount(classification);

    await INSERT.into(entities.Classifications).entries([classification]);

    return {
      tadirObjectType: classification.tadirObjectType as string,
      tadirObjectName: classification.tadirObjectName as string,
      objectType: classification.objectType as string,
      objectName: classification.objectName as string,
      oldRating: NO_CLASS,
      newRating: classification.rating_code as string,
      oldSuccessorClassification: 'undefined',
      newSuccessorClassification:
        classification.successorClassification_code as string,
      status: 'NEW'
    } as ClassificationImportLog;
  } else {
    // Merge Classification
    const existingClassification = await SELECT.one
      .from(entities.Classifications)
      .columns(getAllClassificationColumns)
      .where({
        tadirObjectType: classificationImport.tadirObjectType,
        tadirObjectName: classificationImport.tadirObjectName,
        objectType: classificationImport.objectType,
        objectName: classificationImport.objectName
      });
    // Merge Rating
    let updated = false;
    let conflict = false;
    const oldRatingCode = existingClassification.rating_code;
    const oldSuccessorClassification =
      existingClassification.successorClassification_code;
    if (
      existingClassification.rating_code !=
      (ratingMap.get(classificationImport.rating) || NO_CLASS)
    ) {
      existingClassification.rating_code =
        ratingMap.get(classificationImport.rating) || NO_CLASS;
      updated = true;
    }
    // Merge Successors
    switch (classificationImport.successorClassification) {
      case 'STANDARD':
        if (existingClassification.successorClassification_code == 'CUSTOM') {
          conflict = true;
        } else if (
          !existingClassification.successorClassification_code ||
          existingClassification.successorClassification_code == 'undefined'
        ) {
          existingClassification.successorClassification_code = 'STANDARD';
          updated = true;
          // Merge Successor List
          for (const successor of classificationImport.successorList) {
            // Check if successor already exists
            const existingSuccessor = existingClassification.successorList.find(
              (s) =>
                s.tadirObjectType == successor.tadirObjectType &&
                s.tadirObjectName == successor.tadirObjectName &&
                s.objectType == successor.objectType &&
                s.objectName == successor.objectName
            );
            if (!existingSuccessor) {
              existingClassification.successorList.push({
                ID: utils.uuid(),
                tadirObjectType: successor.tadirObjectType,
                tadirObjectName: successor.tadirObjectName,
                objectType: successor.objectType,
                objectName: successor.objectName,
                successorType_code: 'STANDARD'
              });
            }
          }
        }
        break;
      case 'CUSTOM':
        if (existingClassification.successorClassification_code == 'STANDARD') {
          conflict = true;
        } else if (
          !existingClassification.successorClassification_code ||
          existingClassification.successorClassification_code == 'undefined'
        ) {
          existingClassification.successorClassification_code = 'CUSTOM';
          updated = true;
          // Override Successor List
          existingClassification.successorList =
            classificationImport.successorList.map((successor) => ({
              ID: utils.uuid(),
              tadirObjectType: successor.tadirObjectType,
              tadirObjectName: successor.tadirObjectName,
              objectType: successor.objectType,
              objectName: successor.objectName,
              successorType_code: successor.successorType || 'DIRECT'
            }));
        }
        break;
      default:
        // Leave Successor Classification as is
        break;
    }

    if (conflict) {
      return {
        tadirObjectType: existingClassification.tadirObjectType as string,
        tadirObjectName: existingClassification.tadirObjectName as string,
        objectType: existingClassification.objectType as string,
        objectName: existingClassification.objectName as string,
        oldRating: oldRatingCode as string,
        newRating: existingClassification.rating_code as string,
        oldSuccessorClassification: oldSuccessorClassification,
        newSuccessorClassification:
          existingClassification.successorClassification_code as string,
        status: 'CONFLICT'
      } as ClassificationImportLog;
    } else if (updated) {
      // Update DB
      await UPDATE(entities.Classifications).set(existingClassification).where({
        tadirObjectType: existingClassification.tadirObjectType,
        tadirObjectName: existingClassification.tadirObjectName,
        objectName: existingClassification.objectName,
        objectType: existingClassification.objectType
      });

      return {
        tadirObjectType: existingClassification.tadirObjectType as string,
        tadirObjectName: existingClassification.tadirObjectName as string,
        objectType: existingClassification.objectType as string,
        objectName: existingClassification.objectName as string,
        oldRating: oldRatingCode as string,
        newRating: existingClassification.rating_code as string,
        oldSuccessorClassification: oldSuccessorClassification,
        newSuccessorClassification:
          existingClassification.successorClassification_code as string,
        status: 'UPDATED'
      } as ClassificationImportLog;
    } else {
      // Nothing changed
      return {
        tadirObjectType: existingClassification.tadirObjectType as string,
        tadirObjectName: existingClassification.tadirObjectName as string,
        objectType: existingClassification.objectType as string,
        objectName: existingClassification.objectName as string,
        oldRating: oldRatingCode as string,
        newRating: existingClassification.rating_code as string,
        oldSuccessorClassification: oldSuccessorClassification,
        newSuccessorClassification:
          existingClassification.successorClassification_code as string,
        status: 'UNCHANGED'
      } as ClassificationImportLog;
    }
  }
};

export const importGithubClassificationById = async (
  classificationImportId: string,
  tx: Transaction,
  updateProgress: (progress: number) => Promise<void>
) => {
  // Unzip the file
  const githubImport = await SELECT.one
    .from(entities.Imports, (d: any) => {
      d.ID, d.status, d.title, d.file, d.systemId;
    })
    .where({ ID: classificationImportId });
  const zip = new JSZip();

  const stream = new PassThrough();
  githubImport.file.pipe(stream);
  const buffer = await streamToBuffer(stream);

  try {
    const content = await zip.loadAsync(buffer);

    const classificationSet = await getClassificationSet();
    // Get all releaseState
    const releaseStateMap = await getReleaseStateMap();
    // Ratings
    const ratingMap = await getRatingMap();
    const importLogList: ClassificationImportLog[] = [];
    let processIndex = 0;
    let updateIndex = 0;
    for (const file of Object.keys(content.files)) {
      const classification = JSON.parse(
        await content.files[file].async('string')
      ) as ClassificationImport;
      LOG.info('Importing Classification', { classification });
      const importLog = await importClassification(
        classification,
        classificationSet,
        releaseStateMap,
        ratingMap
      );
      importLogList.push(importLog);
      processIndex++;
      if (importLog.status != 'UNCHANGED') {
        updateIndex++;
      }
      if (processIndex % 10 == 0) {
        await updateProgress(
          Math.round((processIndex / Object.keys(content.files).length) * 100)
        );
      }
      if (updateIndex % 10 == 0) {
        await tx.commit();
      }
    }
    if (updateIndex > 0 && updateIndex % 10 != 0) {
      await tx.commit();
    }
    const file = papa.unparse(importLogList);
    await updateProgress(100);
    // Write to file
    return {
      file: Buffer.from(file, 'utf8'),
      fileName: 'importLog.csv',
      fileType: 'application/csv'
    } as JobResult;
  } catch (e) {
    LOG.error('Error loading ZIP file', { error: e });
    throw new Error('Invalid ZIP file format');
  }
};
