import { Customers, Ratings, Frameworks } from '#cds-models/kernseife/db';
import { entities, log, tx } from '@sap/cds';
import axios from 'axios';
import { getActiveSettings } from './settings-feature';
import { importInitialClassification } from './classification-feature';
import { loadReleaseState } from './releaseState-feature';

const LOG = log('Setup');

export const createInitialData = async (
  contactPerson: string,
  prefix: string,
  customerTitle: string,
  configUrl: string,
  classificationUrl: string
) => {
  if (configUrl) {
    const response = await axios.get<{
      ratingList: Ratings;
      frameworkList: Frameworks;
    }>(configUrl);
    if (response.status != 200) {
      throw new Error('Error fetching Data');
    }

    if (!response.data) {
      throw new Error('No Data found');
    }
    // Check if data is string and parse it
    let configData;
    if (typeof response.data === 'string') {
      configData = JSON.parse(response.data);
    } else {
      configData = response.data;
    }

    LOG.info('Config Data', configData);

    const ratingCount = await SELECT.from(entities.Ratings).columns(
      'IFNULL(COUNT( * ),0) as count'
    );
    if (ratingCount[0]['count'] === 0 && configData.ratingList.length > 0) {
      const ratingList = configData.ratingList.map((rating) => ({
        code: rating.code,
        title: rating.title,
        score: rating.score,
        criticality_code: rating.criticality
      }));
      await INSERT.into(entities.Ratings).entries(ratingList);
    }

    const frameworkCount = await SELECT.from(entities.Frameworks).columns(
      'IFNULL(COUNT( * ),0) as count'
    );
    if (
      frameworkCount[0]['count'] === 0 &&
      configData.frameworkList.length > 0
    ) {
      await INSERT.into(entities.Frameworks).entries(configData.frameworkList);
    }

    // Create Base Customer
    const customerCount = await SELECT.from(entities.Customers).columns(
      'IFNULL(COUNT( * ),0) as count'
    );
    if (customerCount[0]['count'] === 0) {
      await INSERT.into(entities.Customers).entries([
        { contact: contactPerson, prefix: prefix, title: customerTitle }
      ] as Customers);
    }
  }

  if (classificationUrl) {

    const releaseStateCount = await SELECT.from(entities.ReleaseStates).columns(
      'IFNULL(COUNT( * ),0) as count'
    );
    if (releaseStateCount[0]['count'] === 0) {
      await loadReleaseState();
    }

    const response = await axios.get(classificationUrl);
    if (response.status != 200) {
      throw new Error('Error fetching Data');
    }

    if (!response.data) {
      throw new Error('No Data found');
    }
    // Check if data is string and parse it
    const classificationData = response.data;
    if (classificationData)
      await importInitialClassification(classificationData);
  }
};
