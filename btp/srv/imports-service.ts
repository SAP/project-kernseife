import cds from '@sap/cds';
import { fileToBuffer } from './lib/files';
import { Import, JobType } from '#cds-models/kernseife/db';
const LOG = cds.log('ImportsService');

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
    ID: cds.utils.uuid(),
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
  await INSERT.into(cds.entities.Imports).entries(importObject);

  return importObject.ID as string;
};

const uploadFile = async (
  importType: string,
  fileName: string,
  file: any,
  systemId: string | undefined | null,
  defaultRating?: string,
  comment?: string
): Promise<string> => {
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
  let fileType = 'text/csv'; // Default file type
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

export default (srv: cds.Service) => {
  srv.on('UPDATE', 'FileUpload', async (req: any, next: any) => {
    LOG.info('FileUpload');

    const uploadType = req.headers['x-upload-type'];
    const fileName = req.headers['x-file-name'];
    const systemId = req.headers['x-system-id'];
    const defaultRating = req.headers['x-default-rating'];
    const comment = req.headers['x-comment'];

    const buffer = await fileToBuffer(req.data.file);
    const importId = await uploadFile(
      uploadType,
      fileName,
      buffer,
      systemId,
      defaultRating,
      comment
    );

    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: uploadType
      });

      req.notify({
        message: 'Upload Successful',
        status: 200
      });
    } else {
      req.error(400);
    }
  });

  srv.on('Imported', async (msg) => {
    const importId = msg.data.ID;
    const importType = msg.data.type;
    LOG.info(`Imported ${importId} ${importType}`);
    const jobsService = await cds.connect.to('JobsService');
    await jobsService
      .create('Jobs')
      .entries({
        title: 'Test',
        type: ('IMPORT_' + importType) as JobType,
        data: JSON.stringify({ importId })
      });
  });
};
