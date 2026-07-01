import { log } from '@sap/cds';
import { remoteServiceCall } from '../lib/connectivity';
import { Exemptions, System } from '#cds-models/kernseife/db';
import {
  DevelopmentObjectImport,
  FindingImport,
  MissingClassificationImport,
  ProjectImport
} from '../types/imports';
import { Connection } from '../types/connectivity';
import dayjs from 'dayjs';

export const BTP_CONNECTOR_PATH =
  '/sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001/';

const LOG = log('BTP Connector');

export const setupProject = async (connection: Connection) => {
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'POST',
    url:
      BTP_CONNECTOR_PATH +
      'ZKNSF_I_PROJECTS/com.sap.gateway.srvd.zknsf_btp_connector.v0001.Setup',
    data: {}
  });
  LOG.info(
    `Received response from Destination ${connection.destination}: ${response.message}`
  );
  return response.message;
};

export const getProject = async (
  connection: Connection
): Promise<ProjectImport> => {
  // Read Project
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url: BTP_CONNECTOR_PATH + 'ZKNSF_I_PROJECTS'
  });
  LOG.info(
    `Received response from Destination ${connection.destination}: ${JSON.stringify(response?.result?.value)}`
  );
  return response.result.value[0] as ProjectImport;
};

export const triggerAtcRun = async (connection: Connection) => {
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'POST',
    url:
      BTP_CONNECTOR_PATH +
      'ZKNSF_I_PROJECTS/com.sap.gateway.srvd.zknsf_btp_connector.v0001.RunATC',
    data: {}
  });
  LOG.info(
    `Received response from Destination ${connection.destination}: ${response.message}`
  );
  return response.message;
};

export const getDevelopmentObjects = async (
  connection: Connection,
  projectId: string,
  top: number,
  skip: number
): Promise<DevelopmentObjectImport[]> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_DEVELOPMENT_OBJECTS?$top=${top}&$skip=${skip}&$expand=_findings,_metrics,_usages&$filter=projectId eq ${projectId}`
  });
  // LOG.info(
  //   `Received response from Destination ${destination}: ${JSON.stringify(response?.result?.value)}`
  // );
  return response.result.value as DevelopmentObjectImport[];
};

export const getDevelopmentObjectsCount = async (
  connection: Connection,
  projectId: string
): Promise<number> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_DEVELOPMENT_OBJECTS/$count?$filter=projectId eq ${projectId}`
  });
  LOG.info(
    `Received response from Destination ${connection.destination}: ${JSON.stringify(response?.result)}`
  );
  return response.result as number;
};

export const getFindings = async (
  connection: Connection,
  projectId: string,
  runId: string,
  top: number,
  skip: number
): Promise<FindingImport[]> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_FINDINGS?$top=${top}&$skip=${skip}&$filter=projectId eq ${projectId} and runId eq ${runId}`
  });
  // LOG.info(
  //   `Received response from Destination ${destination}: ${JSON.stringify(response?.result?.value)}`
  // );
  return response.result.value as FindingImport[];
};

export const getFindingsCount = async (
  connection: Connection,
  projectId: string,
  runId: string
): Promise<number> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_FINDINGS/$count?$filter=projectId eq ${projectId} and runId eq ${runId}`
  });
  LOG.info(
    `Received response from Destination ${connection.destination}: ${JSON.stringify(response?.result)}`
  );
  return response.result as number;
};

export const getMissingClassifications = async (
  connection: Connection
): Promise<MissingClassificationImport[]> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url: BTP_CONNECTOR_PATH + `ZKNSF_I_MISSING` //TODO we need to do this chunked or not?
  });
  // LOG.info(
  //   `Received response from Destination ${destination}: ${JSON.stringify(response?.result?.value)}`
  // );
  return response.result.value as MissingClassificationImport[];
};

export const getMissingClassificationsCount = async (
  connection: Connection,
  projectId: string,
  runId: string
): Promise<number> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_FINDINGS/$count?$filter=projectId eq ${projectId} and runId eq ${runId}`
  });
  LOG.info(
    `Received response from Destination ${connection.destination}: ${JSON.stringify(response?.result)}`
  );
  return response.result as number;
};

export const syncClassifications = async (
  connection: Connection,
  zipFile: Buffer<ArrayBufferLike>
) => {
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'POST',
    url:
      BTP_CONNECTOR_PATH +
      'ZKNSF_I_PROJECTS/com.sap.gateway.srvd.zknsf_btp_connector.v0001.UploadFile',
    data: {
      dummy: true,
      _StreamProperties: {
        streamProperty: zipFile.toString('base64'),
        mimeType: 'application/zip',
        fileName: `classification_${dayjs().format('YYYY_MM_DD')}.zip`
      }
    }
  });

  LOG.info(
    `Received response from Destination ${connection.destination}: ${JSON.stringify(response?.message)}`
  );
};

export const getDestinationBySystemId = async (systemId: string) => {
  const system: System = await SELECT.one
    .from('kernseife.db.Systems')
    .where({ sid: systemId });
  if (!system || !system.destination) {
    throw new Error(`System ${systemId} not found or no destination assigned`);
  }
  return system.destination;
};

export const getExemptions = async (
  connection: Connection,
  checkClass: string,
  top: number,
  skip: number
): Promise<Exemptions> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_EXEMPTIONS?$top=${top}&$skip=${skip}&$filter=checkClass eq '${checkClass}'`
  });
  // LOG.info(
  //   `Received response from Destination ${destination}: ${JSON.stringify(response?.result?.value)}`
  // );
  return response.result.value as Exemptions;
};

export const getExemptionsCount = async (
  connection: Connection,
  checkClass: string
): Promise<number> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: connection.destination,
    jwtToken: connection.jwtToken,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_EXEMPTIONS/$count?$filter=checkClass eq '${checkClass}'`
  });
  LOG.info(
    `Received response from Destination ${connection.destination}: ${JSON.stringify(response?.result)}`
  );
  return response.result as number;
};
