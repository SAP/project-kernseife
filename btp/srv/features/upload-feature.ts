import { Import } from '#cds-models/kernseife/db';
import { entities, log, services, utils } from '@sap/cds';

const LOG = log('Upload');

const createImport = async (
  importType: string,
  fileName: string,
  file: any,
  fileType: string,
  systemId: string | undefined | null = undefined,
  defaultRating: string | undefined = undefined,
  comment: string | undefined = undefined
): Promise<string> => {
  const importObject = {
    ID: utils.uuid(),
    type: importType,
    title: importType + ' Import ' + fileName,
    status: 'NEW',
    systemId,
    defaultRating,
    comment,
    file,
    fileType
  } as Import;
  // Seperate transaction to avoid issues with File Streams for some reason in SQLite
  await INSERT.into(entities.Imports).entries(importObject);

  return importObject.ID as string;
};

export const uploadFile = async (
  importType: string,
  fileName: string,
  file: any,
  systemId: string | undefined | null,
  defaultRating?: string,
  comment?: string
): Promise<string> => {
  LOG.info('Uploading file', {
    fileName: fileName,
    file,
    type: importType,
    defaultRating,
    systemId,
    comment
  });

  if (!file) {
    throw new Error('No file uploaded');
  }
  let fileType = 'text/csv'; // Default file type
  switch (importType) {
    case 'SCORING':
      if (!systemId) {
        throw new Error('No SystemId provided');
      }
      break;
    case 'MISSING_CLASSIFICATION':
      break;
    case 'ENHANCEMENT':
      break;
    case 'GITHUB_CLASSIFICATION':
      fileType = 'application/zip';
      break;
    default:
      throw new Error('Invalid type provided');
  }
  return await createImport(
    importType,
    fileName,
    file,
    fileType,
    systemId,
    defaultRating,
    comment
  );
};
