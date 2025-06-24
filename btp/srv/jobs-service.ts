import { Job, Jobs, JobType } from '#cds-models/kernseife/db';
import cds from '@sap/cds';
import { JobResult } from './types/file';
import { loadReleaseStateJob } from './features/releaseState-feature';
import {
  exportMissingClassificationJob,
  importEnhancementObjectsById,
  importGithubClassificationById,
  importMissingClassificationsById
} from './features/classification-feature';
import { importScoringById } from './features/developmentObject-feature';
import { JobData } from './types/jobs';
const LOG = cds.log('JobsService');

const updateJobProgress = async (
  id: string,
  tx: cds.Transaction,
  progress: number
) => {
  await UPDATE(cds.entities.Jobs)
    .set({ progressCurrent: progress, status: 'RUNNING' })
    .where({ ID: id });
  if (tx) tx.commit();
};

const getJobFunction = (jobType: JobType, data: JobData) => {
  switch (jobType) {
    case 'IMPORT_RELEASE_STATE':
      return loadReleaseStateJob;
    case 'EXPORT_MISSING_CLASSIFICATION':
      return exportMissingClassificationJob;
    case 'IMPORT_MISSING_CLASSIFICATION':
      return async (
        tx: cds.Transaction,
        updateProgress: (progress: number) => Promise<void>
      ) => importMissingClassificationsById(data.importId!, tx, updateProgress);
    case 'IMPORT_SCORING':
      return async (
        tx: cds.Transaction,
        updateProgress: (progress: number) => Promise<void>
      ) => importScoringById(data.importId, tx, updateProgress);
    case 'IMPORT_ENHANCEMENT':
      return async (
        tx: cds.Transaction,
        updateProgress: (progress: number) => Promise<void>
      ) => importEnhancementObjectsById(data.importId!, tx, updateProgress);
    case 'IMPORT_GITHUB_CLASSIFICATION':
      return async (
        tx: cds.Transaction,
        updateProgress: (progress: number) => Promise<void>
      ) => importGithubClassificationById(data.importId!, tx, updateProgress);
    default:
      throw new Error(`Job type ${jobType} is not implemented`);
  }
};

const finishJob = async (id: string, result?: JobResult) => {
  LOG.info('Job Finished ' + id);
  const job = { status: 'SUCCESS' };
  if (result && result.file && result.fileType) {
    job['file'] = result.file;
    job['fileType'] = result.fileType;
    job['fileName'] = result.fileName || 'result';
  }
  await UPDATE(cds.entities.Jobs, { ID: id }).set(job);
};

const failJob = async (id: string, err) => {
  LOG.error('Job Failed: ' + id, err);
  await UPDATE(cds.entities.Jobs, { ID: id }).with({ status: 'ERROR' });
};

export default (srv: cds.Service) => {
  srv.before('CREATE', 'Jobs', (req) => {
    // Check Parameters
    const { title, type } = req.data;
    if (!type || !title) {
      return req.error(400, `Invalid job parameters`);
    }

    req.data.progressTotal = 100; // Default progress total
    req.data.progressCurrent = 0;
    req.data.status = 'NEW';
  });

  srv.after('CREATE', async (job: Job | Jobs) => {
    LOG.debug('Job Created', job);
    job = job as Job; // Not sure why CAP wants also an array, CREATE never does arrays?!
    // Spawn new process
    cds
      .spawn({ after: 200 }, async (tx: cds.Transaction) => {
        LOG.debug(`Spawned a new process for ${job.type}`);
        const data = (job.data ? JSON.parse(job.data) : {}) as JobData;
        const jobFunction = getJobFunction(job.type!, data);
        return await jobFunction(tx, (progress) =>
          updateJobProgress(job.ID!, tx, progress)
        );
      })
      .on('succeeded', async (result: JobResult) => {
        await finishJob(job.ID!, result);
      })
      .on('failed', async (err) => {
        await failJob(job.ID!, err);
      });
  });
};
