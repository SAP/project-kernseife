import { JobType } from '#cds-models/kernseife/db';
import { connect, entities, log, Service, Transaction } from '@sap/cds';
import { PassThrough, Readable } from 'stream';
import {
  assignFrameworkByRef,
  assignSuccessorByRef,
  getClassificationCount,
  getClassificationJsonCloud,
  getClassificationJsonCustom,
  getClassificationJsonStandard,
  getMissingClassifications,
  importMissingClassificationsById
} from './features/classification-feature';
import {
  calculateCleanCoreScoreAll,
  calculateScoreAll,
  calculateScoreByRef,
  importLanguageVersionById,
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

export default (srv: Service) => {
  const LOG = log('AdminService');

  srv.on('PUT', 'FileUpload', async (req: any, next: any) => {
    LOG.info('FileUpload');

    const uploadType = req.headers['x-upload-type'];
    const fileName = req.headers['x-file-name'];
    const systemId = req.headers['x-system-id'];
    const defaultRating = req.headers['x-default-rating'];
    const comment = req.headers['x-comment'];

    const stream = new PassThrough();
    const buffers = [] as any[];
    req.data.file.pipe(stream);
    await new Promise((resolve) => {
      stream.on('data', (dataChunk: any) => {
        buffers.push(dataChunk);
      });
      stream.on('end', async () => {
        const buffer = Buffer.concat(buffers);
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
        resolve(undefined);
      });
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
    await createInitialData(contactPerson, prefix, customerTitle, configUrl, classificationUrl);
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
        LOG.error('type', type);
        switch (type) {
          case 'MISSING_CLASSIFICATION':
            return await importMissingClassificationsById(
              ID,
              tx,
              updateProgress
            );
          case 'SCORING':
            return await importScoringById(ID, tx, updateProgress);
          case 'LANGUAGE_VERSION':
            return await importLanguageVersionById(ID, tx, updateProgress);
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

  srv.on('calculateScore', async (req) => {
    LOG.debug('Calculate Score');
    return await calculateScoreByRef(req.subject);
  });

  srv.on('calculateScoreAll', async () => {
    await calculateScoreAll();
    await calculateCleanCoreScoreAll();
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
    const mimetype = 'application/json';
    const filename = downloadType + '.json';
    LOG.info('Download', { downloadType, mimetype, filename });
    let content;
    switch (downloadType) {
      case 'classificationStandard':
        content = await getClassificationJsonStandard();
        break;
      case 'classificationCustom':
        content = await getClassificationJsonCustom();
        break;
      case 'classificationCloud':
        content = await getClassificationJsonCloud();
        break;
      case 'missingClassifications':
        content = await getMissingClassifications();
        break;
      default:
        return req.error(400, `Download Type ${downloadType} not found`);
    }
    req.reply(Readable.from([JSON.stringify(content)]), { mimetype, filename });
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
