import {
  DevelopmentObject,
  Import,
  FindingRecord,
  DevelopmentObjects,
  DevelopmentObjectUsage,
  DevelopmentObjectFindings,
  DevelopmentObjectFinding,
  FindingsAggregated
} from '#cds-models/kernseife/db';
import { db, log, Transaction } from '@sap/cds';
import { text } from 'node:stream/consumers';
import papa from 'papaparse';
import {
  getRatingMap,
  getSuccessorKey,
  getSuccessorRatingMap
} from './classification-feature';
import { supportslanguageVersions } from '../lib/languageVersions';
import { JobResult } from '../types/jobs';
import {
  getDestinationBySystemId,
  getDevelopmentObjects,
  getDevelopmentObjectsCount,
  getFindings,
  getFindingsCount,
  getProject
} from './btp-connector-feature';
import { CleanCoreLevel } from '#cds-models/kernseife/enums';
import JSZip from 'jszip';
import { PassThrough } from 'node:stream';
import { isZipFile, streamToBuffer } from '../lib/files';

const LOG = log('DevelopmentObjectFeature');

// Required fields for FINDINGS import
const REQUIRED_FINDINGS_FIELDS = [
  'itemId',
  'objectType',
  'objectName',
  'devClass',
  'softwareComponent',
  'messageId',
  'refObjectType',
  'refObjectName'
];

export interface CsvValidationResult {
  isValid: boolean;
  errors: string[];
}

/**
 * Validates that the CSV has the required columns
 */
export const validateFindingsCsvColumns = (
  csvHeaders: string[]
): CsvValidationResult => {
  const errors: string[] = [];
  const headers = csvHeaders.map((h) => h.trim().toUpperCase());

  // Check required fields
  for (const requiredField of REQUIRED_FINDINGS_FIELDS) {
    if (!headers.includes(requiredField.toUpperCase())) {
      errors.push(`Missing required column '${requiredField}'`);
    }
  }

  if (errors.length > 0) {
    LOG.error('CSV Validation Failed', {
      errors,
      headers
    });
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

export const getDevelopmentObjectCount = async () => {
  const result = await SELECT.from('kernseife.db.DevelopmentObjects').columns(
    'IFNULL(COUNT( * ),0) as count'
  );
  return result[0]['count'];
};

export const getTotalScore = async () => {
  const result = await SELECT.from('kernseife.db.DevelopmentObjects').columns(
    'IFNULL(SUM( score ), 0) as score'
  );
  return result[0]['score'];
};

export const determineNamespace = (developmentObject: DevelopmentObject) => {
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

export const calculateNamespaces = async () => {
  if (db.kind != 'sqlite') {
    await db.run(
      "UPDATE kernseife_db_DEVELOPMENTOBJECTS SET NAMESPACE = CASE SUBSTRING(OBJECTNAME,1,1) WHEN 'Z' THEN 'Z' WHEN 'Y' THEN 'Y' WHEN '/' THEN SUBSTR_REGEXPR('(^/.*/).+$' IN OBJECTNAME GROUP 1) ELSE ''  END"
    );
  }
};

export const calculateScores = async () => {
  // we could put all operations into once Statement, but this is easier to debug

  // Update Development Object Finding Totals
  await db.run(
    'UPDATE kernseife_db_DEVELOPMENTOBJECTFINDINGS as d SET total = d.count * (SELECT IFNULL(score,0) FROM kernseife_db_RATINGS WHERE code = d.code)'
  );
  //TODO Update totalPercent

  // Calculate Total Score for all Development Objects
  await db.run(
    'UPDATE kernseife_db_DEVELOPMENTOBJECTS as d SET score = IFNULL(' +
      '(SELECT sum(IFNULL(f.total,0)) AS sum_score ' +
      'FROM kernseife_db_DEVELOPMENTOBJECTFINDINGS as f ' +
      'WHERE f.objectType = d.objectType AND f.objectName = d.objectName AND f.devClass = d.devClass AND f.systemId = d.systemId ' +
      ',0)'
  );

  // Calculate Name spaces
  await calculateNamespaces();
  // Calculate Reference Count & Score
  await db.run(
    'UPDATE kernseife_db_CLASSIFICATIONS as c SET ' +
      'referenceCount =  IFNULL((SELECT SUM(count) FROM kernseife_db_DEVELOPMENTOBJECTFINDINGS as f WHERE f.refObjectType = c.objectType AND f.refObjectName = c.objectName),0),' +
      'totalScore = IFNULL((SELECT SUM(total) FROM kernseife_db_DEVELOPMENTOBJECTFINDINGS as f WHERE f.refObjectType = c.objectType AND f.refObjectName = c.objectName),0)'
  );
};

export const calculateScoreAndLevel = (
  ratingMap: Map<string, { level: CleanCoreLevel; score: number }>,
  findingList: DevelopmentObjectFindings
): {
  score: number;
  potentialScore: number;
  level: CleanCoreLevel;
  potentialLevel: CleanCoreLevel;
} => {
  return findingList.reduce(
    (acc, finding) => {
      const potentialRating = ratingMap.get(finding.potentialCode!);
      const rating = ratingMap.get(finding.code!);
      if (!rating || !potentialRating) throw Error('Rating Config missmatch');

      return {
        score: acc.score + (finding.total || 0),
        potentialScore:
          acc.potentialScore +
          ratingMap.get(finding.potentialCode!)!.score * finding.count!,

        level: rating.level! > acc.level ? rating.level : acc.level,
        potentialLevel:
          potentialRating.level! > acc.potentialLevel
            ? potentialRating.level
            : acc.potentialLevel
      };
    },
    {
      score: 0,
      potentialScore: 0,
      level: CleanCoreLevel.A,
      potentialLevel: CleanCoreLevel.A
    } as {
      score: number;
      potentialScore: number;
      level: CleanCoreLevel;
      potentialLevel: CleanCoreLevel;
    }
  );
};

export const getDevelopmentObjectIdentifier = (
  object: FindingRecord | DevelopmentObject
) => {
  return (
    (object.systemId || '') +
    (object.devClass || '') +
    (object.objectType || '') +
    (object.objectName || '')
  );
};

export const getDevelopmentObjectMap = async () => {
  const developmentObjectDB: DevelopmentObjects = await SELECT.from(
    'kernseife.db.DevelopmentObjects'
  );
  return developmentObjectDB.reduce((map, developmentObject) => {
    return map.set(
      getDevelopmentObjectIdentifier(developmentObject),
      developmentObject
    );
  }, new Map<string, DevelopmentObject>()) as Map<string, DevelopmentObject>;
};

export const importFindingsCSV = async (
  findingImport: Import,
  tx?: Transaction,
  updateProgress?: (progress: number) => Promise<void>
): Promise<JobResult> => {
  if (!findingImport.file) throw new Error('File broken');
  let csv: string;
  if (isZipFile(findingImport.fileType!)) {
    // Unzip file and get CSV content
    const zip = new JSZip();

    const stream = new PassThrough();
    findingImport.file.pipe(stream);
    const buffer = await streamToBuffer(stream);

    try {
      const content = await zip.loadAsync(buffer);
      const file = Object.keys(content.files)[0]; // Only take the first file, as we expect only one
      LOG.error('Unzipping file', { file });
      csv = await content.files[file].async('text');
    } catch (e) {
      LOG.error('Error unzipping file', { error: e });
      throw new Error('Error unzipping file: ' + e);
    }
  } else {
    csv = await text(findingImport.file);
  }

  const result = papa.parse<any>(csv, {
    header: true,
    skipEmptyLines: true
  });

  // Validate CSV columns before processing
  if (!result.meta.fields || result.meta.fields.length === 0) {
    throw new Error('CSV file is empty or has no headers');
  }

  const validation = validateFindingsCsvColumns(result.meta.fields);
  if (!validation.isValid) {
    const errorMessage = `Invalid CSV format. ${validation.errors.join('. ')}`;
    LOG.error('CSV Validation Failed', {
      errors: validation.errors,
      headers: result.meta.fields
    });
    throw new Error(errorMessage);
  }

  LOG.info('CSV columns validated successfully', {
    headers: result.meta.fields
  });

  const successorMap = await getSuccessorRatingMap();

  const itemIdSet = new Set();

  const findingRecordList = result.data
    .map((finding) => {
      if (itemIdSet.has(finding.itemId || finding.ITEMID || finding.itemID)) {
        // duplicate!
        throw new Error(
          'Duplicate ItemId ' +
            (finding.itemId || finding.ITEMID || finding.itemID)
        );
      }

      itemIdSet.add(finding.itemId || finding.ITEMID || finding.itemID);

      const findingRecord = {
        // Map Attribues
        import_ID: findingImport.ID,
        systemId: findingImport.systemId,
        itemId: finding.itemId || finding.ITEMID || finding.itemID,
        objectType: finding.objectType || finding.OBJECTTYPE,
        objectName: finding.objectName || finding.OBJECTNAME,
        devClass: finding.devClass || finding.DEVCLASS,
        softwareComponent:
          finding.softwareComponent || finding.SOFTWARECOMPONENT,
        refObjectType: finding.refObjectType || finding.REFOBJECTTYPE,
        refObjectName: finding.refObjectName || finding.REFOBJECTNAME,
        messageId:
          finding.messageId ||
          finding.MESSAGEID ||
          finding.messageid ||
          finding.MESSAGE_ID
      } as FindingRecord;

      // Calculate Potential Message Id
      // check if messageId ends with _SUC
      if (!findingRecord.messageId) {
        LOG.error('Missing MessageId', { finding, findingRecord });
      }

      if (findingRecord.messageId!.endsWith('_SUC')) {
        // Find Successors
        const successorKey = getSuccessorKey(
          findingRecord.refObjectType!,
          findingRecord.refObjectName!
        );
        findingRecord.potentialMessageId = successorMap.get(successorKey);

        //LOG.info('Finding has a Successor', { findingRecord, successorKey });
      }
      if (!findingRecord.potentialMessageId) {
        // No Successor, so use the same as messageId
        findingRecord.potentialMessageId = findingRecord.messageId;
      }
      return findingRecord;
    })
    .filter((finding) => {
      if (!finding.objectType || !finding.objectName) {
        LOG.warn('Invalid finding', { finding });
        return false;
      }
      return true;
    });

  if (findingRecordList == null || findingRecordList.length == 0) {
    return { message: 'No Records to import' } as JobResult;
  }

  await INSERT.into('kernseife.db.FindingRecords').entries(findingRecordList);
  if (tx) {
    await tx.commit();
  }

  LOG.info(`Importing Findings ${findingRecordList.length}`);

  await prepareNewDevelopmentObjectsImport(
    findingImport.ID!,
    findingImport.systemId!
  );
  if (tx) {
    await tx.commit();
  }

  const ratingMap = await getRatingMap();

  let progressCount = 0;
  let insertCount = 0;
  const chunkSize = 1000;

  const map = new Map<string, string>();

  // Only look at the Language Version Findings, as there should exist only one per Development Object
  // use splice instead of filter to reduce memory usage
  let j = 0;
  for (let i = 0, l = findingRecordList.length; i < l; i++) {
    const messageId = findingRecordList[i].messageId;
    if (messageId == 'X' || messageId == '2' || messageId == '5') {
      const id = getDevelopmentObjectIdentifier(findingRecordList[i]);
      if (map.has(id)) {
        // already exists, skip this record
        LOG.error(`Development Object exists multiple times: ${id}`);
        continue;
      }
      findingRecordList[j++] = findingRecordList[i];
      map.set(id, messageId);
    }
  }
  findingRecordList.length = j;

  for (let i = 0; i < findingRecordList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${findingRecordList.length}`);
    const chunk = findingRecordList.slice(i, i + chunkSize);

    const developmentObjectInsert = [] as DevelopmentObjects;
    for (const findingRecord of chunk) {
      progressCount++;

      // Create a new Development Object
      const developmentObject = {
        objectType: findingRecord.objectType || '',
        objectName: findingRecord.objectName,
        systemId: findingRecord.systemId || '',
        devClass: findingRecord.devClass || '',
        softwareComponent: findingRecord.softwareComponent || '',
        version_ID: findingImport.ID,
        languageVersion_code: findingRecord.messageId,
        namespace: '',
        difficulty: 0, // Not available via import by file
        numberOfChanges: 0 // Not available via import by file
      } as DevelopmentObject;

      // Process the DevelopmentObjectFindings, cause we need it to calculate stuff later
      const developmentObjectFindingList = await getDevelopmentObjectFindings(
        developmentObject,
        findingImport.ID!
      );
      await createDevelopmentObjectFindings(developmentObjectFindingList);

      const { score, potentialScore, level, potentialLevel } =
        calculateScoreAndLevel(ratingMap, developmentObjectFindingList);

      calculateTotalPercent(developmentObjectFindingList, score);

      developmentObject.potentialScore = potentialScore;
      developmentObject.score = score;

      developmentObject.level =
        level == CleanCoreLevel.A &&
        findingRecord.messageId != '5' &&
        findingRecord.messageId != '2' // Key-User is also Part of ABAP Cloud => Level A as well
          ? CleanCoreLevel.B
          : level;

      const supportsABAPCloud = supportslanguageVersions(
        developmentObject.objectType!
      );
      developmentObject.potentialLevel =
        !supportsABAPCloud && potentialLevel == CleanCoreLevel.A
          ? CleanCoreLevel.B
          : potentialLevel; // As if all findings are level A, the object could have Language Version 5
      //TODO We might need to define the list of object types which can have Language Version 5
      developmentObject.namespace = determineNamespace(developmentObject);

      if (
        !developmentObject.devClass ||
        !developmentObject.objectName ||
        !developmentObject.objectType ||
        !developmentObject.systemId
      ) {
        LOG.error('Invalid Development Object', { developmentObject });
      }
      developmentObjectInsert.push(developmentObject);

      insertCount++;
    }
    if (developmentObjectInsert.length > 0) {
      await createDevelopmentObjects(developmentObjectInsert);
      if (tx) {
        await tx.commit();
      }
    }
    if (updateProgress)
      await updateProgress(
        Math.round((100 / findingRecordList.length) * progressCount)
      );
  }
  if (insertCount > 0) {
    return { message: `Inserted ${insertCount} DevelopmentObject(s)` };
  } else {
    throw new Error(
      'No Development Objects found. Please check the Check Properties.'
    );
  }
};

export const importFindingsCSVById = async (
  findingImportId: string,
  tx: Transaction,
  updateProgress?: (progress: number) => Promise<void>
): Promise<JobResult> => {
  const findingsRunImport = await SELECT.one
    .from('kernseife.db.Imports', (d: Import) => {
      d.ID, d.title, d.file, d.fileType, d.systemId, d.createdAt;
    })
    .where({ ID: findingImportId });
  return await importFindingsCSV(findingsRunImport, tx, updateProgress);
};

const importFindingsBTPBySystem = async (
  importId: string,
  systemId: string,
  successorMap: Map<string, string>,
  tx: Transaction,
  updateProgress?: (progress: number) => Promise<void>
): Promise<number> => {
  // Get Destination from System
  const destination = await getDestinationBySystemId(systemId);
  // Get Project Id
  const project = await getProject({ destination });

  let top = 1000;
  let skip = 0;

  // Process Findings
  const findingsCount = await getFindingsCount(
    { destination },
    project.projectId,
    project.runId
  );
  LOG.info(`Found ${findingsCount} Findings for Project ${project.projectId}`);

  let findingsCounter = 0;
  skip = 0;
  while (findingsCount > findingsCounter) {
    const findingsImportList = await getFindings(
      { destination },
      project.projectId,
      project.runId,
      top,
      skip
    );

    if (!findingsImportList || findingsImportList.length == 0) {
      findingsCounter = findingsCount;
    }
    // Insert Findings
    const findingRecordList = findingsImportList.map((finding) => {
      const findingRecord = {
        // Map Attribues
        import_ID: importId,
        systemId: systemId,
        itemId: finding.itemId,
        objectType: finding.objectType,
        objectName: finding.objectName,
        devClass: finding.devClass,
        softwareComponent: finding.softwareComponent,
        refObjectType: finding.refObjectType,
        refObjectName: finding.refObjectName,
        messageId: finding.messageId
      } as FindingRecord;

      if (findingRecord.messageId!.endsWith('_SUC')) {
        // Find Successors
        const successorKey = getSuccessorKey(
          findingRecord.refObjectType!,
          findingRecord.refObjectName!
        );
        findingRecord.potentialMessageId = successorMap.get(successorKey);
      }
      if (!findingRecord.potentialMessageId) {
        // No Successor, so use the same as messageId
        findingRecord.potentialMessageId = findingRecord.messageId;
      }

      return findingRecord;
    });

    await INSERT.into('kernseife.db.FindingRecords').entries(findingRecordList);
    if (tx) {
      await tx.commit();
    }

    findingsCounter += findingsImportList.length;
    skip += top;
    if (updateProgress)
      await updateProgress(Math.round((50 / findingsCount) * findingsCounter));
  }

  await prepareNewDevelopmentObjectsImport(importId, systemId);
  if (tx) {
    await tx.commit();
  }

  // Get Development Objects
  let insertCount = 0;

  const ratingMap = await getRatingMap();
  const map = new Map<string, string>();

  const developmentObjectCount = await getDevelopmentObjectsCount(
    { destination },
    project.projectId
  );
  top = 100;
  skip = 0;
  while (skip < developmentObjectCount) {
    const developmentObjectImportList = await getDevelopmentObjects(
      { destination },
      project.projectId,
      top,
      skip
    );

    const developmentObjectInsert = [] as Partial<DevelopmentObject>[];
    const usageInsert = [] as Partial<DevelopmentObjectUsage>[];
    for (const developmentObjectImport of developmentObjectImportList) {
      const id = getDevelopmentObjectIdentifier(developmentObjectImport);
      if (map.has(id)) {
        LOG.error(`Development Object exists multiple times: ${id}`);
        continue;
      }
      map.set(id, developmentObjectImport.languageVersion);
      // Create a new Development Object
      const developmentObject = {
        objectType: developmentObjectImport.objectType,
        objectName: developmentObjectImport.objectName,
        systemId: systemId,
        devClass: developmentObjectImport.devClass,
        softwareComponent: developmentObjectImport.softwareComponent,
        version_ID: importId,
        languageVersion_code: developmentObjectImport.languageVersion,
        difficulty: developmentObjectImport._metrics?.difficulty || 0,
        numberOfChanges: developmentObjectImport._metrics?.numberOfChanges || 0,
        namespace: ''
      } as DevelopmentObject;

      // Process the DevelopmentObjectFindings, cause we need it to calculate stuff later
      const developmentObjectFindingList = await getDevelopmentObjectFindings(
        developmentObject,
        importId
      );
      await createDevelopmentObjectFindings(developmentObjectFindingList);

      const { score, potentialScore, level, potentialLevel } =
        calculateScoreAndLevel(ratingMap, developmentObjectFindingList);
      calculateTotalPercent(developmentObjectFindingList, score);

      developmentObject.potentialScore = potentialScore;
      developmentObject.score = score;

      developmentObject.level =
        level == CleanCoreLevel.A &&
        developmentObjectImport.languageVersion != '5' &&
        developmentObjectImport.languageVersion != '2' // Key-User is also Part of ABAP Cloud => Level A as well
          ? CleanCoreLevel.B
          : level;

      const supportsABAPCloud = supportslanguageVersions(
        developmentObject.objectType!
      );
      developmentObject.potentialLevel =
        !supportsABAPCloud && potentialLevel == CleanCoreLevel.A
          ? CleanCoreLevel.B
          : potentialLevel; // As if all findings are level A, the object could have Language Version 5
      //TODO We might need to define the list of object types which can have Language Version 5
      developmentObject.namespace = determineNamespace(developmentObject);

      if (
        !developmentObject.devClass ||
        !developmentObject.objectName ||
        !developmentObject.objectType ||
        !developmentObject.systemId
      ) {
        LOG.error('Invalid Development Object', { developmentObject });
      }

      developmentObjectInsert.push(developmentObject);

      insertCount++;

      // Usages
      if (
        developmentObjectImport._usages &&
        developmentObjectImport._usages.length > 0
      ) {
        usageInsert.push(
          ...developmentObjectImport._usages.map((usage) => ({
            entryPointObjectType: usage.entry_point_type,
            entryPointObjectName: usage.entry_point_name,
            objectType: usage.obj_type,
            objectName: usage.obj_name,
            counter: usage.counter,
            lastUsed: usage.last_used
          }))
        );
      }
    }
    if (developmentObjectInsert.length > 0) {
      await createDevelopmentObjects(developmentObjectInsert);
      if (tx) {
        await tx.commit();
      }
    }

    if (usageInsert.length > 0) {
      await INSERT.into('kernseife.db.DevelopmentObjectUsages').entries(
        usageInsert
      );
      if (tx) {
        await tx.commit();
      }
    }

    if (updateProgress)
      await updateProgress(
        50 + Math.round((50 / project.totalObjectCount) * insertCount)
      );
    skip += top;
  }

  return insertCount;
};

export const importFindingsBTP = async (
  importId: string,
  tx: Transaction,
  updateProgress?: (progress: number) => Promise<void>
): Promise<JobResult> => {
  const developmentObjectsImport = await SELECT.one
    .from('kernseife.db.Imports', (d: Import) => {
      d.ID, d.title, d.systemId, d.createdAt;
    })
    .where({ ID: importId });

  const systemId = developmentObjectsImport.systemId;

  const successorMap = await getSuccessorRatingMap();

  let insertCount = 0;

  if (systemId == 'ALL') {
    const systemList = await SELECT.from('AdminService.BTPSystems').columns(
      'sid'
    );
    for (const system of systemList) {
      insertCount += await importFindingsBTPBySystem(
        importId,
        system.sid,
        successorMap,
        tx,
        updateProgress
      );
    }
  } else {
    insertCount = await importFindingsBTPBySystem(
      importId,
      systemId,
      successorMap,
      tx,
      updateProgress
    );
  }

  return {
    message: `Inserted ${insertCount} DevelopmentObject(s)`,
    exportIdList: []
  } as JobResult;
};

const createDevelopmentObjects = async (
  developmentObjectsList: DevelopmentObjects
) => {
  await INSERT.into('kernseife.db.DevelopmentObjects').entries(
    developmentObjectsList
  );

  // Also add them to History
  await INSERT.into('kernseife.db.HistoricDevelopmentObjects').entries(
    developmentObjectsList
  );
};

const createDevelopmentObjectFindings = async (
  developmentObjectFindingList: DevelopmentObjectFindings
) => {
  await INSERT.into('kernseife.db.DevelopmentObjectFindings').entries(
    developmentObjectFindingList
  );

  //TODO Check if we need to commit?
};

const prepareNewDevelopmentObjectsImport = async (
  importID: string,
  systemId: string
) => {
  // Remove all Development Objects for this System
  await DELETE.from('kernseife.db.DevelopmentObjects').where({
    systemId: systemId
  });

  await DELETE.from('kernseife.db.DevelopmentObjectFindings').where({
    systemId: systemId
  });
  // Create new DevelopmentObjectVersion
  await INSERT.into('kernseife.db.DevelopmentObjectVersions').entries([
    { ID: importID, systemId: systemId }
  ]);
};

const getDevelopmentObjectFindings = async (
  developmentObject: DevelopmentObject,
  versionId: string
) => {
  // Select all FindingsRecords for Development Object aggregated
  const findingList: FindingsAggregated[] = await SELECT.from(
    'kernseife.db.FindingsAggregated'
  )
    .columns(
      'refObjectType',
      'refObjectName',
      'softwareComponent',
      'code',
      'potentialCode',
      'count',
      'total'
    )
    .where({
      importId: versionId, // as we use the same UUID for both
      objectType: developmentObject.objectType,
      objectName: developmentObject.objectName,
      devClass: developmentObject.devClass,
      systemId: developmentObject.systemId
    });

  // Convert to Development ObjectFindings
  return findingList.map(
    (finding) =>
      ({
        version_ID: versionId,
        objectType: developmentObject.objectType,
        objectName: developmentObject.objectName,
        devClass: developmentObject.devClass,
        systemId: developmentObject.systemId,
        softwareComponent: developmentObject.softwareComponent,
        refObjectType: finding.refObjectType,
        refObjectName: finding.refObjectName,
        code: finding.code,
        potentialCode: finding.potentialCode,
        count: finding.count,
        total: finding.total,
        totalPercentage: 0
      }) as DevelopmentObjectFinding
  );
};

export const calculateTotalPercent = (
  findingList: DevelopmentObjectFindings,
  score: number
) => {
  findingList.forEach((finding) => {
    finding.totalPercentage =
      score == 0 ? 0 : (100 / score) * (finding.total || 0);
  });
};
