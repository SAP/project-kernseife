import { JobType } from '#cds-models/kernseife/db';
import { connect, entities, log, Service, Transaction } from '@sap/cds';
import { Readable } from 'stream';
import {
  assignFrameworkByRef,
  assignSuccessorByRef,
  getClassificationCount,
  getClassificationJsonCloud,
  getClassificationJsonCustom,
  getClassificationJsonStandard,
  getMissingClassifications,
  importGithubClassificationById,
  importMissingClassificationsById
} from './features/classification-feature';
import {
  calculateScores,
  calculateScoreByRef,
  importScoringById
} from './features/developmentObject-feature';
import {
  addAllUnassignedDevelopmentObjects,
  addDevelopmentObject,
  addDevelopmentObjectsByDevClass,
  removeAllDevelopmentObjects
} from './features/extension-feature';
import { runAsJob } from './features/jobs-feature';
import {
  loadReleaseState,
  updateClassificationsFromReleaseStates
} from './features/releaseState-feature';
import { createInitialData } from './features/setup-feature';
import { uploadFile } from './features/upload-feature';
import { JobResult } from './types/file';
import papa from 'papaparse';
import JSZip from 'jszip';
import { readFile } from './lib/middleware/file';

export default (srv: Service) => {
  const LOG = log('AdminService');

  srv.on('PUT', 'FileUpload', async (req: any, next: any) => {
    LOG.info('FileUpload');

    const uploadType = req.headers['x-upload-type'];
    const fileName = req.headers['x-file-name'];
    const systemId = req.headers['x-system-id'];
    const defaultRating = req.headers['x-default-rating'];
    const comment = req.headers['x-comment'];

    const buffer = await readFile(req.data.file);

    try {
      await uploadFile(
        uploadType,
        fileName,
        buffer,
        systemId,
        defaultRating,
        comment
      );
    } catch (e) {
      return req.error(400, e);
    }
    req.notify({
      message: 'Upload Successful',
      status: 200
    });
  });

  srv.on(
    'clearDevelopmentObjectList',
    ['Extensions', 'Extensions.drafts'],
    async ({ subject, params }) => {
      LOG.info('clearDevelopmentObjectList', { subject, params });
      await removeAllDevelopmentObjects(subject);
    }
  );

  srv.on(
    'addUnassignedDevelopmentObjects',
    ['Extensions', 'Extensions.drafts'],
    async ({ subject, params }) => {
      LOG.info('addUnassignedDevelopmentObjects', { subject, params });
      await addAllUnassignedDevelopmentObjects(subject);
    }
  );

  srv.on(
    'addDevelopmentObjectsByDevClass',
    ['Extensions', 'Extensions.drafts'],
    async (req: any) => {
      LOG.info('addDevelopmentObjectsByDevClass', req);
      const devClass = req.data.devClass;
      if (!devClass) {
        return req.error(400, `Package Required`);
      }
      const result = await addDevelopmentObjectsByDevClass(
        req.subject,
        devClass
      );
      LOG.info('addDevelopmentObjectsByDevClass Result', result);
      req.notify({
        message: 'Added Objects Successful',
        status: 200
      });
    }
  );

  srv.on(
    'addDevelopmentObject',
    ['Extensions', 'Extensions.drafts'],
    async (req) => {
      LOG.info('addDevelopmentObject', req);
      const objectName = req.data.objectName;
      const objectType = req.data.objectType;
      const devClass = req.data.devClass;
      if (!devClass || !objectName || !objectType) {
        return req.error(400, `Missing mandatory parameter`);
      }
      await addDevelopmentObject(req.subject, objectType, objectName, devClass);
    }
  );

  srv.on('createInitialData', ['Settings', 'Settings.drafts'], async (req) => {
    LOG.info('createInitialData');
    const contactPerson = req.data.contactPerson;
    const prefix = req.data.prefix;
    const customerTitle = req.data.customerTitle;
    if (!contactPerson || !prefix || !customerTitle) {
      return req.error(400, `Missing mandatory parameter`);
    }
    const configUrl = req.data.configUrl;
    const classificationUrl = req.data.classificationUrl;
    await createInitialData(
      contactPerson,
      prefix,
      customerTitle,
      configUrl,
      classificationUrl
    );
  });

  srv.on('loadReleaseState', async () => {
    LOG.info('loadReleaseState');
    await runAsJob(
      'Import Release States',
      'IMPORT_RELEASE_STATE',
      100,
      async (tx, updateProgress) => {
        await loadReleaseState();
        await updateProgress(25);
        const classificationsCount = await getClassificationCount();
        await updateClassificationsFromReleaseStates(
          tx,
          async (progress) =>
            await updateProgress(25 + (progress / classificationsCount) * 75)
        );
        await updateProgress(100);
      }
    );
  });

  srv.on('exportMissingClassification', async () => {
    LOG.info('exportMissingClassification');
    await runAsJob(
      'Export Missing Classifications',
      'EXPORT_MISSING_CLASSIFICATION',
      100,
      async (tx, updateProgress) => {
        const missingClassification = await getMissingClassifications();
        await updateProgress(75);
        const file = papa.unparse(missingClassification);
        await updateProgress(100);
        // Write to file
        return {
          file: Buffer.from(file, 'utf8'),
          fileName: 'missing_classification.csv',
          fileType: 'application/csv'
        } as JobResult;
      }
    );
  });

  srv.on('Imported', async (msg) => {
    const ID = msg.data.ID;
    const type = msg.data.type;
    LOG.info(`Imported ${ID} ${type}`);

    await runAsJob(
      `Import ${type}`,
      `IMPORT_${type}` as JobType,
      100,
      async (
        tx: Transaction,
        updateProgress: (progress: number) => Promise<void>
      ) => {
        LOG.info('type', type);
        switch (type) {
          case 'MISSING_CLASSIFICATION':
            return await importMissingClassificationsById(
              ID,
              tx,
              updateProgress
            );
          case 'SCORING':
            return await importScoringById(ID, tx, updateProgress);
          case 'GITHUB_CLASSIFICATION':
            return await importGithubClassificationById(ID, tx, updateProgress);
          default:
            LOG.error(`Unknown Import Type ${type}`);
            throw new Error(`Unknown Import Type ${type}`);
        }
      },
      async () => {
        const db = await connect.to('db');
        const tx = db.tx();
        try {
          await tx.run(
            UPDATE(entities.Imports).set({ status: 'FAILED' }).where({ ID })
          );
          await tx.commit();
        } catch (e) {
          LOG.error(e);
          await tx.rollback();
        }
      },
      async () => {
        const db = await connect.to('db');
        const tx = db.tx();
        try {
          await tx.run(
            UPDATE(entities.Imports)
              .set({ status: 'IMPORTED', progress: 100 })
              .where({ ID })
          );
          await tx.commit();
        } catch (e) {
          LOG.error(e);
          await tx.rollback();
        }
      }
    );
  });

  srv.on('recalculateScore', async (req) => {
    LOG.debug('Calculate Score');
    return await calculateScoreByRef(req.subject);
  });

  srv.on('recalculateAllScores', async () => {
    await calculateScores();
  });

  srv.before(
    'DELETE',
    ['SuccessorClassifications', 'SuccessorClassifications.drafts'],
    async (req) => {
      // Don't allow deletion of Successors which are still used
      const result = await SELECT.one.from(entities.Classifications).where({
        successorClassification_Code: (req.params[0] as { Code: string }).Code
      });
      if (!result || !result.custom) {
        // Not allowed to delete
        return req.error(400, `Only custom entries can be deleted`);
      }
    }
  );

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  srv.on('GET', 'Downloads', async (req: any) => {
    const downloadType = req._.req.path.replace('/Downloads/', '');

    LOG.info('Download', { downloadType });
    let content;
    switch (downloadType) {
      case 'classificationStandard': {
        const mimetype = 'application/json';
        const filename = downloadType + '.json';
        const classificationJson = await getClassificationJsonStandard();
        content = JSON.stringify(classificationJson);
        req.reply(Readable.from([content]), { mimetype, filename });
        break;
      }
      case 'classificationCustom': {
        const mimetype = 'application/json';
        const filename = downloadType + '.json';
        const classificationJson = await getClassificationJsonCustom();
        content = JSON.stringify(classificationJson);
        req.reply(Readable.from([content]), { mimetype, filename });
        break;
      }
      case 'classificationCloud': {
        const mimetype = 'application/json';
        const filename = downloadType + '.json';
        const classificationJson = await getClassificationJsonCloud();
        content = JSON.stringify(classificationJson);
        req.reply(Readable.from([content]), { mimetype, filename });
        break;
      }
      case 'classificationGithub': {
        const mimetype = 'application/zip';
        const filename = downloadType + '.zip';
        const classificationJson = await getClassificationJsonCloud();
        // Wrap in ZIP
        const zip = new JSZip();

        for (const classification of classificationJson.objectClassifications) {
          if (
            classification.tadirObjectType === classification.objectType &&
            classification.tadirObjectName === classification.objectName
          ) {
            zip.file(
              `${classification.objectName.replaceAll('/', '#').toLowerCase()}.${classification.objectType.toLowerCase()}.json`,
              JSON.stringify(classification, null, 2)
            );
          } else {
            zip.file(
              `${classification.tadirObjectName.replaceAll('/', '#').toLowerCase()}.${classification.tadirObjectType.toLowerCase()}.${classification.objectName.replaceAll('/', '#').toLowerCase()}.${classification.objectType.toLowerCase()}.json`,
              JSON.stringify(classification, null, 2)
            );
          }
        }
        content = await zip.generateAsync({
          type: 'nodebuffer',
          compression: 'DEFLATE',
          compressionOptions: { level: 7 }
        });
        req.reply(Readable.from([content]), { mimetype, filename });
        break;
      }
      default: {
        return req.error(400, `Download Type ${downloadType} not found`);
      }
    }
  });

  srv.on(
    'assignFramework',
    ['Classifications', 'Classifications.drafts'],
    async (req: any) => {
      const code = req.data.frameworkCode;
      LOG.debug('assignFramework', { code });
      return await assignFrameworkByRef(req.subject, code);
    }
  );

  srv.on(
    'assignSuccessor',
    ['Classifications', 'Classifications.drafts'],
    async (req: any) => {
      const tadirObjectType = req.data.tadirObjectType;
      const tadirObjectName = req.data.tadirObjectName;
      const objectType = req.data.objectType;
      const objectName = req.data.objectName;
      const successorType = req.data.successorType;
      LOG.debug('assignSuccssor', {
        tadirObjectType,
        tadirObjectName,
        objectType,
        objectName,
        successorType
      });
      return await assignSuccessorByRef(
        req.subject,
        tadirObjectType,
        tadirObjectName,
        objectType,
        objectName,
        successorType
      );
    }
  );
};
