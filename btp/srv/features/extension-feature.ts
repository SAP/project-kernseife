import { entities, log } from '@sap/cds';

const LOG = log("ExtensionFeature");

export const removeAllDevelopmentObjects = async (ref) => {
    // read Extension Object
    const extension = await SELECT.one.from(ref, e => { e.ID });
    LOG.info("Removing all DevelopmentObjects for Extension " + extension.title, extension);

    await UPDATE.entity(entities.DevelopmentObjects)
        .set({
            extension_ID: null,
        })
        .where({ extension_ID: extension.ID });
}

export const addAllUnassignedDevelopmentObjects = async (ref) => {
    // read Extension Object
    const extension = await SELECT.one.from(ref, e => { e.ID, e.system() });
    await UPDATE.entity(entities.DevelopmentObjects)
        .set({
            extension_ID: extension.ID,
        })
        .where({ extension_ID: null, systemId: extension.system.sid });
}

export const addDevelopmentObjectsByDevClass = async (ref, devClass) => {
    // read Extension Object
    const extension = await SELECT.one.from(ref, e => { e.ID, e.system() });
    return await UPDATE.entity(entities.DevelopmentObjects)
        .set({
            extension_ID: extension.ID,
        })
        .where({ extension_ID: null, systemId: extension.system.sid, devClass: devClass });
}

export const addDevelopmentObject = async (ref, objectType, objectName, devClass) => {
    // read Extension Object
    const extension = await SELECT.one.from(ref, e => { e.ID, e.system() });
    await UPDATE.entity(entities.DevelopmentObjects)
        .set({
            extension_ID: extension.ID,
        })
        .where({ extension_ID: null, systemId: extension.system.sid, devClass: devClass, objectType: objectType, objectName: objectName });
}