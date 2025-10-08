import {
  Classification,
  ClassificationSuccessor,
  ReleaseState
} from '#cds-models/kernseife/db';
import cds from '@sap/cds';
import axios from 'axios';
import { CUSTOM, STANDARD } from './classification-feature';
import { EnhancementImport } from '../types/imports';

const LOG = cds.log('ReleaseStateFeature');

export const getReleaseStateKey = (
  releaseState: Classification | ReleaseState | EnhancementImport
) => {
  return (
    (releaseState.tadirObjectType || '') +
    (releaseState.tadirObjectName || '') +
    (releaseState.objectType || '') +
    (releaseState.objectName || '')
  );
};

export const getReleaseStateCount = async () => {
  const result = await SELECT.from(cds.entities.ReleaseStates).columns(
    'COUNT( * ) as count'
  );
  return result[0]['count'];
};

export const getReleaseStateMap = async (): Promise<
  Map<string, ReleaseState>
> => {
  const releaseStates = await SELECT.from(cds.entities.ReleaseStates, (r) => {
      r.tadirObjectType,
      r.tadirObjectName,
      r.objectType,
      r.objectName,
      r.releaseInfo_code,
      r.classicInfo_code,
      r.releaseLevel_code,
      r.applicationComponent,
      r.softwareComponent,
      r.successorClassification_code,
      r.successorList();
  });
  return releaseStates.reduce((map, releaseState) => {
    return map.set(getReleaseStateKey(releaseState), releaseState);
  }, new Map());
};

export const determineReleaseLevel = (releaseState) => {
  if (releaseState.releaseInfo_code === 'released') {
    return 'RELEASED';
  } else if (releaseState.releaseInfo_code === 'deprecated') {
    if (
      releaseState.classicInfo_code === 'internalAPI' ||
      releaseState.classicInfo_code === 'noAPI'
    )
      return 'CONFLICT';
    return 'DEPRECATED';
  } else if (releaseState.classicInfo_code === 'classicAPI') {
    return 'CLASSIC';
  } else if (releaseState.releaseInfo_code === 'notToBeReleasedStable') {
    return 'STABLE';
  } else if (releaseState.classicInfo_code === 'internalAPI') {
    return 'INTERNAL';
  } else if (releaseState.classicInfo_code === 'noAPI') {
    return 'NO_API';
  } else if (
    releaseState.releaseInfo_code === 'notToBeReleased'
  ) {
    return 'NOT_TO_BE_RELEASED';
  }

  return 'undefined';
};

export const updateReleaseState = (
  classification: Classification,
  releaseStateMap: Map<string, ReleaseState>
) => {
  let updated = false;
  // Check if Release State exists now
  const releaseState = releaseStateMap.get(getReleaseStateKey(classification));

  if (!releaseState) {
    // Reset Classification
    if (!classification.releaseLevel_code) {
      classification.releaseLevel_code = 'undefined';
      updated = true;
    }

    // Reset Successor Classification in case of no Release State
    if (
      !classification.successorClassification_code ||
      classification.successorClassification_code === STANDARD
    ) {
      classification.successorClassification_code = 'undefined';
      updated = true;
    }

    // remove Standard Successors in case of no Release State
    if (
      classification.successorList &&
      classification.successorList.filter(
        (successor) => successor.successorType_code === STANDARD
      ).length > 0
    ) {
      classification.successorList = classification.successorList.filter(
        (successor) => successor.successorType_code !== STANDARD
      );
      updated = true;
    }
  } else {
    // Update Release State
    if (classification.releaseLevel_code !== releaseState.releaseLevel_code) {
      classification.releaseLevel_code = releaseState.releaseLevel_code;
      updated = true;
    }

    // Update Successor Classification to Standard in case there is one
    if (
      (!classification.successorClassification_code ||
        classification.successorClassification_code === 'undefined') &&
      releaseState.successorList &&
      releaseState.successorList.length > 0
    ) {
      classification.successorClassification_code = STANDARD;
      updated = true;
    }

    // Check if Successors are still the same
    if (releaseState.successorList) {
      if (
        !classification.successorList ||
        JSON.stringify(
          classification.successorList
            .filter((successor) => successor.successorType_code === STANDARD)
            .map((successor) => ({
              objectName: successor.objectName,
              objectType: successor.objectType
            }))
        ) !==
          JSON.stringify(
            releaseState.successorList.map((successor) => ({
              objectName: successor.objectName,
              objectType: successor.objectType
            }))
          )
      ) {
        classification.successorList = [
          ...(classification.successorList
            ? classification.successorList.filter(
                (successor) => successor.successorType_code !== STANDARD
              )
            : []),
          ...releaseState.successorList.map(
            (successor) =>
              ({
                objectName: successor.objectName,
                objectType: successor.objectType,
                tadirObjectType: successor.tadirObjectType,
                tadirObjectName: successor.tadirObjectName,
                successorType_code: STANDARD
              }) as ClassificationSuccessor
          )
        ];
        updated = true;
      }

      if (classification.successorClassification_code === CUSTOM) {
        classification.comment = `Successor Conflict`;
        LOG.error('Successor Conflict', classification);
      }
    }
  }
  return updated;
};

export const loadReleaseState = async () => {
  // Delete existing ReleaseStates
  await DELETE.from(cds.entities.ReleaseStates);

  const client = axios.create({
    baseURL: 'https://raw.githubusercontent.com'
  });

  const releaseStateMap = new Map();

  // Release Info API
  const responseReleaseInfo = await client.get(
    'SAP/abap-atc-cr-cv-s4hc/main/src/objectReleaseInfo_PCELatest.json'
  );

  responseReleaseInfo.data.objectReleaseInfo.forEach((releaseInfo) => {
    // Cleanup Object Types

    // Check if the object is already in the map releaseStateMap
    const key =
      releaseInfo.tadirObject +
      releaseInfo.tadirObjName +
      releaseInfo.objectType +
      releaseInfo.objectKey;
    let releaseState = releaseStateMap.get(key);
    // Add the object to the map if it is not already in the map
    if (!releaseState) {
      releaseState = {
        objectType: releaseInfo.objectType,
        objectName: releaseInfo.objectKey,
        tadirObjectType: releaseInfo.tadirObject,
        tadirObjectName: releaseInfo.tadirObjName,
        softwareComponent: releaseInfo.softwareComponent,
        applicationComponent: releaseInfo.applicationComponent,
        successorList: releaseInfo.successors?.map((successor) => {
          // Map Successor
          return {
            objectType: successor.objectType,
            objectName: successor.objectKey,
            tadirObjectType: successor.tadirObject,
            tadirObjectName: successor.tadirObjName
          };
        })
      };
      releaseStateMap.set(key, releaseState);
    }

    // Set the state of the releaseState
    releaseState.releaseInfo_code = releaseInfo.state
      ? releaseInfo.state
      : undefined;

    // Set the successorClassification of the releaseState
    releaseState.successorClassification_code =
      releaseInfo.successorClassification
        ? releaseInfo.successorClassification
        : 'undefined';
  });

  // Classic API
  const responseClassicInfo = await client.get(
    'SAP/abap-atc-cr-cv-s4hc/refs/heads/main/src/objectClassifications_SAP.json'
  );

  responseClassicInfo.data.objectClassifications.forEach(
    (objectClassification) => {
      // Cleanup Object Types

      // Check if the object is already in the map releaseStateMap
      const key =
        objectClassification.tadirObject +
        objectClassification.tadirObjName +
        objectClassification.objectType +
        objectClassification.objectKey;
      let releaseState = releaseStateMap.get(key);
      // Add the object to the map if it is not already in the map
      if (!releaseState) {
        releaseState = {
          objectType: objectClassification.objectType,
          objectName: objectClassification.objectKey,
          tadirObjectType: objectClassification.tadirObject,
          tadirObjectName: objectClassification.tadirObjName,
          softwareComponent: objectClassification.softwareComponent,
          applicationComponent: objectClassification.applicationComponent,
          successorList: objectClassification.successors?.map((successor) => {
            // Map Successor
            return {
              objectType: successor.objectType,
              objectName: successor.objectKey,
              tadirObjectType: successor.tadirObject,
              tadirObjectName: successor.tadirObjName
            };
          }),
          labelList: objectClassification.labels || []
        };
        releaseStateMap.set(key, releaseState);
      }

      // Set the state of the releaseState
      releaseState.classicInfo_code = objectClassification.state
        ? objectClassification.state
        : undefined;

      // Set the successorClassification of the releaseState
      releaseState.successorClassification_code =
        objectClassification.successorClassification
          ? objectClassification.successorClassification
          : 'undefined';
    }
  );

  const releaseStateList = [...releaseStateMap.values()];
  releaseStateList.forEach((releaseState) => {
    releaseState.releaseLevel_code = determineReleaseLevel(releaseState);
  });

  // Insert Release States
  LOG.info('Inserting Release States', releaseStateList.length);
  await INSERT.into(cds.entities.ReleaseStates).entries(releaseStateList);
};

export const updateClassificationsFromReleaseStates = async (
  tx,
  updateProgress
) => {
  const classifications = await SELECT.from(
    cds.entities.Classifications,
    (c) => {
      c.tadirObjectType,
        c.tadirObjectName,
        c.objectType,
        c.objectName,
        c.applicationComponent,
        c.softwareComponent,
        c.adoptionEffort_code,
        c.releaseLevel_code,
        c.successorClassification_code,
        c.successorList();
    }
  );
  const releaseStateMap = await getReleaseStateMap();

  let progressCount = 0;
  const chunkSize = 50;
  for (let i = 0; i < classifications.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${classifications.length}`);
    const chunk = classifications.slice(i, i + chunkSize);

    const updateClassifications = await chunk.filter((classification) =>
      updateReleaseState(classification, releaseStateMap)
    );

    if (updateClassifications.length > 0) {
      for (const classification of updateClassifications) {
        // Update Base Attributes
        await UPDATE.entity(cds.entities.Classifications, {
          tadirObjectType: classification.tadirObjectType,
          tadirObjectName: classification.tadirObjectName,
          objectType: classification.objectType,
          objectName: classification.objectName,
          applicationComponent: classification.applicationComponent
        }).with(classification);
      }

      // Update Successors
      for (const classification of updateClassifications) {
        await DELETE.from(cds.entities.ClassificationSuccessors).where({
          classification_tadirObjectType: classification.tadirObjectType,
          classification_tadirObjectName: classification.tadirObjectName,
          classification_objectName: classification.objectName,
          classification_objectType: classification.objectType
        });
        if (classification.successorList) {
          await INSERT.into(cds.entities.ClassificationSuccessors).entries(
            classification.successorList.map((successor) => ({
              ...successor,
              classification_tadirObjectType: classification.tadirObjectType,
              classification_tadirObjectName: classification.tadirObjectName,
              classification_objectName: classification.objectName,
              classification_objectType: classification.objectType
            }))
          );
        }
      }
    }
    progressCount += chunk.length;
    if (tx) {
      await tx.commit();
    }
    await updateProgress(progressCount);
  }
};
