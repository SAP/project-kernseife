
import { JobType } from "#cds-models/kernseife/db";
import cds from "@sap/cds";

const LOG = cds.log("Jobs");

export const createJob = async (title: string, type: JobType, progressTotal: number) => {
  const id = cds.utils.uuid();
  await INSERT.into(cds.entities.Jobs).entries({
    ID: id,
    title,
    type,
    progressTotal,
    progressCurrent: 0,
    status: "NEW",
  });
  LOG.info("Job Started " + title + " (" + id + ")");
  return id;
};

export const updateJobProgress = async (id: string, tx: cds.Transaction, progress: number) => {
  await UPDATE(cds.entities.Jobs).set({ progressCurrent: progress, status: "RUNNING" }).where({ ID: id });
  if (tx) tx.commit();
};

export const finishJob = async (id: string) => {
  LOG.info("Job Finished " + id)
  await UPDATE(cds.entities.Jobs, { ID: id }).set({ status: "SUCCESS" });
};

export const failJob = async (id: string, err) => {
  LOG.error("Job Failed: " + id, err);
  await UPDATE(cds.entities.Jobs, { ID: id }).with({ status: "ERROR" });
};


export const runAsJob = async (title: string, type: JobType, progressTotal: number, jobFunction: (tx: cds.Transaction, updateProgress: (progressNumber: number) => Promise<void>) => Promise<void>, errorHandler?: () => Promise<void>, successHandler?: () => Promise<void>) => {
  if (!Number.isInteger(progressTotal)) {
    throw new Error("progressTotal is Not a Number: " + progressTotal)
  }
  const jobId = await createJob(title, type, progressTotal);

  cds.spawn({ after: 200 }, async (tx: cds.Transaction) => {
    await jobFunction(tx, (progress) => updateJobProgress(jobId, tx, progress));
  })
    .on("succeeded", async () => {
      await finishJob(jobId);
      if (successHandler) await successHandler();
    })
    .on("failed", async (err) => {
      await failJob(jobId, err);
      if (errorHandler) await errorHandler();
    });
};

