import { Setting } from "#cds-models/kernseife/db";
import cds from "@sap/cds";

const LOG = cds.log("Settings");

export const getActiveSettings = async (): Promise<Setting> => {
  const result = await SELECT.one.from(cds.entities.Settings)
  //.columns("")
  .where({ ID: "1" });
  LOG.info("settings", result);
  return result;
}
