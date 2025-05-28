import { Import } from '#cds-models/kernseife/db';
import { db, entities, log, services, utils } from '@sap/cds';

const LOG = log('Upload');

const createImport = async (
  importType: string,
  fileName: string,
  file: any,
  fileType: string,
  systemId: string | undefined | null,
  defaultRating?: string,
  comment?: string
) => {
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

  services.AdminService.emit('Imported', {
    ID: importObject.ID,
    type: importObject.type
  });
};

export const uploadFile = async (
  importType: string,
  fileName: string,
  file: any,
  systemId: string | undefined | null,
  defaultRating?: string,
  comment?: string
) => {
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

  switch (importType) {
    case 'SCORING':
      if (!systemId) {
        throw new Error('No SystemId provided');
      }
      await createImport(
        importType,
        fileName,
        file,
        'application/csv',
        systemId,
        defaultRating,
        comment
      );
      break;
    case 'MISSING_CLASSIFICATION':
      await createImport(
        importType,
        fileName,
        file,
        'application/csv',
        systemId,
        defaultRating,
        comment
      );
      break;
    case 'GITHUB_CLASSIFICATION':
      await createImport(
        importType,
        fileName,
        file,
        'application/zip',
        systemId,
        defaultRating,
        comment
      );
      break;
    default:
      throw new Error('Invalid type provided');
  }
};
