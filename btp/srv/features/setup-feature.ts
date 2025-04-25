import { Customers, Ratings, Frameworks } from "#cds-models/kernseife/db";
import { entities, log } from "@sap/cds";
import axios from "axios";
import { getActiveSettings } from "./settings-feature";


const LOG = log("Setup");

export const createInitialData = async (contactPerson: string, prefix: string, customerTitle: string) => {

  // Load Initial Data from github
  const settings = await getActiveSettings();

  if (!settings.initialDataUrl) {
    throw new Error("No Data Url defined");
  }

  const response = await axios.get<{ ratingList: Ratings, frameworkList: Frameworks }>(settings.initialDataUrl);
  if (response.status != 200) {
    throw new Error("Error fetching Data");
  }

  const initialData = response.data;
  LOG.info("Initial Data", initialData);

  const ratingCount = await SELECT.from(entities.Ratings).columns("IFNULL(COUNT( * ),0) as count");
  if (ratingCount[0]["count"] === 0) {
    await INSERT.into(entities.Ratings).entries(initialData.ratingList);
  }

  const frameworkCount = await SELECT.from(entities.Frameworks).columns("IFNULL(COUNT( * ),0) as count");
  if (frameworkCount[0]["count"] === 0) {
    await INSERT.into(entities.Frameworks).entries(initialData.frameworkList);
  }

  // Create Base Customer
  const customerCount = await SELECT.from(entities.Customers).columns("IFNULL(COUNT( * ),0) as count");
  if (customerCount[0]["count"] === 0) {
    await INSERT.into(entities.Customers).entries([{ contact: contactPerson, prefix: prefix, title: customerTitle }] as Customers);
  }
}

