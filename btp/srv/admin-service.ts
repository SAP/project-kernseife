import { BTPSystems, Jobs } from '#cds-models/AdminService';
import { log, Service, Transaction, i18n } from '@sap/cds';
import dayjs from 'dayjs';
import {
  getClassificationCount,
  getClassificationJsonAsZip,
  getClassificationJsonExternal,
  getClassificationJsonCustom,
  importExternalClassificationById,
  importMissingClassificationsById,
  importMissingClassificationsBTP
} from './features/classification-feature';
import {
  importFindingsCSVById,
  importFindingsBTP
} from './features/developmentObject-feature';

import {
  createExport,
  createImport,
  jobHasExports,
  jobHasImports,
  runAsJob,
  setJobIdForImport
} from './features/jobs-feature';
import { createInitialData } from './features/setup-feature';
import JSZip from 'jszip';
import { handleMessage, updateDestinations } from './lib/connectivity';
import { JobResult } from './types/jobs';
import {
  getProject,
  setupProject,
  syncClassifications,
  triggerAtcRun
} from './features/btp-connector-feature';
import { System } from '#cds-models/kernseife/db';
import { isZipFile } from './lib/files';

export default (srv: Service) => {
  const LOG = log('AdminService');

  srv.on('importMissingClassificationsFile', async (req: any) => {
    LOG.info('importMissingClassificationsFile');

    if (req.data.file.mimeType != 'text/csv') {
      req.error(400, 'FILE_TYPE_NOT_SUPPORTED');
      return;
    }

    const importId = await createImport(
      'MISSING_CLASSIFICATION',
      req.data.file.fileName,
      req.data.file.stream,
      req.data.file.mimeType
    );

    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: 'MISSING_CLASSIFICATION'
      });
    } else {
      req.error(400, 'IMPORT_CREATION_FAILED');
      return;
    }

    req.notify({
      message: 'IMPORT_STARTED',
      status: 200
    });
  });

  srv.on('importMissingClassificationsBTP', async (req: any) => {
    LOG.info('importMissingClassifications');

    const importId = await createImport(
      'BTP_MISSING_CLASSIFICATION',
      '',
      null,
      '',
      req.data.systemId,
      false
    );

    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: 'BTP_MISSING_CLASSIFICATION'
      });
    } else {
      req.error(400, 'IMPORT_CREATION_FAILED');
      return;
    }

    req.notify({
      message: 'IMPORT_STARTED',
      status: 200
    });
  });

  srv.on('importFindingsFile', async (req: any) => {
    LOG.info('importFindingsFile');

    if (
      req.data.file.mimeType != 'text/csv' &&
      !isZipFile(req.data.file.mimeType)
    ) {
      req.error(400, 'FILE_TYPE_NOT_SUPPORTED');
      return;
    }

    const importId = await createImport(
      'FINDINGS',
      req.data.file.fileName,
      req.data.file.stream,
      req.data.file.mimeType,
      req.data.systemId
    );

    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: 'FINDINGS'
      });
    }
    req.notify({
      message: 'IMPORT_STARTED',
      status: 200
    });
  });

  srv.on('importFindingsBTP', async (req: any) => {
    LOG.info('importFindingsBTP');

    const importId = await createImport(
      'BTP_FINDINGS',
      '',
      null,
      '',
      req.data.systemId,
      false
    );

    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: 'BTP_FINDINGS'
      });
    } else {
      req.error(400, 'IMPORT_CREATION_FAILED');
      return;
    }

    req.notify({
      message: 'IMPORT_STARTED',
      status: 200
    });
  });

  srv.on('importClassifications', async (req: any) => {
    LOG.info('importClassifications');

    if (req.data.file.mimeType != 'application/zip') {
      req.error(400, 'FILE_TYPE_NOT_SUPPORTED');
      return;
    }

    const importId = await createImport(
      'EXTERNAL_CLASSIFICATION',
      req.data.file.fileName,
      req.data.file.stream,
      req.data.file.mimeType,
      req.data.systemId,
      req.data.overwriteExisting
    );

    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: 'EXTERNAL_CLASSIFICATION'
      });

      req.notify({
        message: 'Upload Successful',
        status: 200
      });
    } else {
      req.error(400);
    }
  });

  srv.on('createInitialData', ['Settings', 'Settings.drafts'], async (req) => {
    LOG.info('createInitialData');
    const configUrl = req.data.configUrl;
    await createInitialData(configUrl);
  });

  srv.on('Imported', async (msg) => {
    const ID = msg.data.ID;
    const importType = msg.data.type;
    LOG.info(`Imported ${ID} ${importType}`);

    const jobId = await runAsJob(
      `Import ${importType}`,
      `IMPORT_${importType}`,
      100,
      async (
        tx: Transaction,
        updateProgress: (progress: number) => Promise<void>
      ): Promise<JobResult> => {
        LOG.info('importType', importType);
        switch (importType) {
          case 'MISSING_CLASSIFICATION':
            return await importMissingClassificationsById(
              ID,
              tx,
              updateProgress
            );
          case 'FINDINGS':
            return await importFindingsCSVById(ID, tx, updateProgress);
          // case 'ENHANCEMENT':
          //   return await importEnhancementObjectsById(ID, tx, updateProgress);
          // case 'EXPLICIT':
          //   return await importExpliticObjectsById(ID, tx, updateProgress);
          case 'EXTERNAL_CLASSIFICATION':
            return await importExternalClassificationById(
              ID,
              tx,
              updateProgress
            );
          case 'BTP_FINDINGS':
            return await importFindingsBTP(ID, tx, updateProgress);
          case 'BTP_MISSING_CLASSIFICATION':
            return await importMissingClassificationsBTP(
              ID,
              tx,
              updateProgress
            );
          default:
            LOG.error(`Unknown Import Type ${importType}`);
            throw new Error(`Unknown Import Type ${importType}`);
        }
      }
    );

    await setJobIdForImport(ID, jobId);
  });

  srv.before(
    'READ',
    ['Destinations', 'Destinations.drafts'],
    async (req: any) => {
      await updateDestinations();
    }
  );

  srv.on('setupSystem', ['Systems', 'Systems.drafts'], async (req: any) => {
    const system: System = await SELECT.one.from(req.subject);
    if (!system || !system.destination) {
      return {
        message: 'SYSTEM_NO_DESTINATION',
        numericSeverity: 3
      };
    }

    const message = await setupProject({
      destination: system.destination,
      jwtToken: req.headers.authorization
    });
    handleMessage(req, message);
  });

  srv.on('triggerATCRun', ['Systems', 'Systems.drafts'], async (req: any) => {
    const system: System = await SELECT.one.from(req.subject);
    if (!system || !system.destination) {
      return {
        message: 'SYSTEM_NO_DESTINATION',
        numericSeverity: 3
      };
    }

    const message = await triggerAtcRun({
      destination: system.destination,
      jwtToken: req.headers.authorization
    });
    handleMessage(req, message);
  });

  // Read Project via System
  srv.after('READ', ['Systems', 'Systems.drafts'], async (Systems, req) => {
    for (const system of Systems as any[]) {
      system.setupDone = false;
      system.setupNotDone = true;
      if (system.destination) {
        try {
          const project = await getProject({
            destination: system.destination,
            jwtToken: req.headers.authorization
          });

          if (project && project.projectId) {
            system.project = project;
            system.setupDone = true;
            system.setupNotDone = false; // As UI Bindings cannot handle negation
          }
        } catch (e) {
          LOG.error('Error getting Project for System', {
            systemId: system.ID,
            error: e
          });
        }
      }
    }
  });

  // Read Project via System
  srv.after('READ', ['Jobs'], async (jobs, req) => {
    for (const job of jobs as Jobs) {
      // Check if Job has Imports
      job.hideImports = !(await jobHasImports(job.ID!));
      job.hideExports = !(await jobHasExports(job.ID!));
    }
  });

  srv.on('exportClassificationsFile', async (req: any) => {
    LOG.info('exportClassificationsFile', req.data);

    switch (req.data.format) {
      case 'SYSTEM':
        await runAsJob(
          `Export SYSTEM_CLASSIFICATION`,
          `EXPORT_SYSTEM_CLASSIFICATION`,
          100,
          async (
            tx: Transaction,
            updateProgress: (progress: number) => Promise<void>
          ): Promise<JobResult> => {
            const fileType = 'application/zip';
            const filename = `system_classification_${dayjs().format('YYYY_MM_DD')}.zip`;
            await updateProgress(15);
            const classificationJson = await getClassificationJsonCustom({
              legacy: req.data.useLegacy
            });
            await updateProgress(85);
            const file = await getClassificationJsonAsZip(classificationJson);
            await updateProgress(100);
            return {
              message: `Exported ${classificationJson.objectClassifications.length} classifications`,
              exportIdList: [
                await createExport(
                  'SYSTEM_CLASSIFICATION',
                  filename,
                  file,
                  fileType
                )
              ]
            };
          }
        );
        break;
      case 'EXTERNAL':
        await runAsJob(
          `Export EXTERNAL_CLASSIFICATION`,
          `EXPORT_EXTERNAL_CLASSIFICATION`,
          100,
          async (
            tx: Transaction,
            updateProgress: (progress: number) => Promise<void>
          ): Promise<JobResult> => {
            // Wrap in ZIP
            const count = await getClassificationCount(req.data.dateFrom);
            let offset = 0;
            const rowSize = 100000;
            let classificationList;
            const exportList: string[] = [];
            do {
              const zip = new JSZip();
              const fileType = 'application/zip';
              const filename = `external_classification_${dayjs().format('YYYY_MM_DD')}_${offset + 1}.zip`;
              const progress = Math.round((100 / count) * rowSize * offset);
              classificationList = await getClassificationJsonExternal(
                rowSize,
                offset * rowSize,
                req.data.dateFrom
              );
              if (tx) await tx.commit(); // Commit Read

              if (classificationList.length === 0) {
                return {
                  message: `No classifications found`,
                  exportIdList: []
                };
              }
              for (const classification of classificationList) {
                if (
                  classification.tadirObjectType ===
                    classification.objectType &&
                  classification.tadirObjectName === classification.objectName
                ) {
                  zip.file(
                    `${classification.objectName.replaceAll('/', '#').toUpperCase()}.${classification.objectType.toUpperCase()}.json`,
                    JSON.stringify(classification, null, 2)
                  );
                } else {
                  zip.file(
                    `${classification.tadirObjectName.replaceAll('/', '#').toUpperCase()}.${classification.tadirObjectType.toUpperCase()}.${classification.objectName.replaceAll('/', '#').toLowerCase()}.${classification.objectType.toUpperCase()}.json`,
                    JSON.stringify(classification, null, 2)
                  );
                }
              }
              offset++;

              await updateProgress(progress);

              LOG.info('Generate Zip - Start ' + Object.keys(zip.files).length);
              const file = await zip.generateAsync({
                streamFiles: true,
                type: 'nodebuffer',
                compression: 'DEFLATE',
                compressionOptions: { level: 7 }
              });

              LOG.info('Generate Zip - Finish');

              exportList.push(
                await createExport(
                  'EXTERNAL_CLASSIFICATION',
                  filename,
                  file,
                  fileType
                )
              );
              if (tx) await tx.commit();
            } while (classificationList.length == rowSize);

            await updateProgress(100);
            return {
              message: `Exported ${count} classifications`,
              exportIdList: exportList
            };
          }
        );
        break;
    }
  });

  srv.on('exportClassificationsBTP', async (req: any) => {
    LOG.info('exportClassificationsBTP', req.data);
    await runAsJob(
      `Export BTP_CLASSIFICATION`,
      `EXPORT_BTP_CLASSIFICATION`,
      100,
      async (
        tx: Transaction,
        updateProgress: (progress: number) => Promise<void>
      ): Promise<JobResult> => {
        let systemList: BTPSystems = [];
        if (req.data.systemId == 'ALL') {
          systemList = await SELECT.from('AdminService.BTPSystems');
        } else {
          systemList = await SELECT.from('AdminService.BTPSystems').where({
            sid: req.data.systemId
          });
        }

        if (systemList.length === 0) {
          return {
            message: `No BTP Systems found`,
            exportIdList: []
          };
        }

        const classificationJson = await getClassificationJsonCustom();
        const zipFile = await getClassificationJsonAsZip(classificationJson);
        await updateProgress(20);
        let count = 0;
        for (const system of systemList) {
          await syncClassifications(
            { destination: system.destination! },
            zipFile
          );
          count++;
          await updateProgress(
            20 + Math.round((80.0 / systemList.length) * count)
          );
        }
        const fileType = 'application/zip';
        const filename = `system_classification_${dayjs().format('YYYY_MM_DD')}.zip`;

        await updateProgress(100);
        return {
          message: `Exported classifications to ${systemList.length} systems`,
          exportIdList: [
            await createExport(
              'SYSTEM_CLASSIFICATION',
              filename,
              zipFile,
              fileType
            )
          ]
        };
      }
    );
  });

  srv.on('READ', `BTPSystems`, async (req: any) => {
    const result = await SELECT.from('AdminService.BTPSystems');
    return [{ sid: 'ALL', title: i18n.labels.at('allSystems') }, ...result];
  });
};
