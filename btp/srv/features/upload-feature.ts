import { Import } from '#cds-models/kernseife/db';
import { entities, log, services, utils } from '@sap/cds';

const LOG = log('Upload');

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
      {
        if (!systemId) {
          throw new Error('No SystemId provided');
        }
        // Map UploadType to Import Type
        const importObject = {
          ID: utils.uuid(),
          type: importType,
          title: importType + ' Import ' + fileName,
          status: 'NEW',
          systemId: systemId,
          defaultRating: undefined,
          comment: undefined,
          file,
          fileType: 'text/csv'
        } as Import;

        await INSERT.into(entities.Imports).entries(importObject);

        services.AdminService.emit('Imported', {
          ID: importObject.ID,
          type: importObject.type
        });
      }
      break;
    case 'MISSING_CLASSIFICATION':
      {
        // Map UploadType to Import Type
        const importObject = {
          ID: utils.uuid(),
          type: importType,
          title: importType + ' Import ' + fileName,
          status: 'NEW',
          systemId: undefined,
          defaultRating: defaultRating,
          comment: comment,
          file,
          fileType: 'text/csv'
        } as Import;

        await INSERT.into(entities.Imports).entries(importObject);

        services.AdminService.emit('Imported', {
          ID: importObject.ID,
          type: importObject.type
        });
      }
      break;
    case 'GITHUB_CLASSIFICATION':
      {
        const importObject = {
          ID: utils.uuid(),
          type: importType,
          title: importType + ' Import ' + fileName,
          status: 'NEW',
          systemId: undefined,
          defaultRating: undefined,
          comment: comment,
          file,
          fileType: 'application/zip'
        } as Import;

        await INSERT.into(entities.Imports).entries(importObject);

        services.AdminService.emit('Imported', {
          ID: importObject.ID,
          type: importObject.type
        });
      }
      break;
    default:
      throw new Error('Invalid type provided');
  }
};
