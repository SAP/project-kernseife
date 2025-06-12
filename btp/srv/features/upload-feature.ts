import { Import } from '#cds-models/kernseife/db';
import { entities, log, services, utils, connect } from '@sap/cds';

import { importCloudClassifications } from './classification-feature';
import { runAsJob } from './jobs-feature';

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

        LOG.info('Imported File', {
          systemId: systemId
        });

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

        LOG.info('Imported File', {
          systemId: systemId
        });

        services.AdminService.emit('Imported', {
          ID: importObject.ID,
          type: importObject.type
        });
      }
      break;
    case 'IMPORT_CLOUD_CLASSIFICATION':
      {
        const content = file.toString();
        const classificationImport = JSON.parse(content).classifications;

        await runAsJob(
          'Import Cloud Classifications',
          'IMPORT_CLOUD_CLASSIFICATION',
          classificationImport.length,
          (tx, progress) =>
            importCloudClassifications(classificationImport, tx, progress)
        );
      }
      break;
    case 'ENHANCEMENT':
      {
        // Map UploadType to Import Type
        const importObject = {
          ID: utils.uuid(),
          type: importType,
          title: importType + ' Import ' + fileName,
          status: 'NEW',
          systemId: undefined,
          defaultRating: undefined,
          comment: undefined,
          file,
          fileType: 'text/csv'
        } as Import;

        await INSERT.into(entities.Imports).entries(importObject);

        LOG.info('Imported File');

        const adminServie = await connect.to('AdminService');

        adminServie.emit('Imported', {
          ID: importObject.ID,
          type: importObject.type
        });
      }
      break;
    default:
      throw new Error('Invalid type provided');
  }
};
