# Frequently Asked Questions / Known Issues

## Why can't I select/delete the uploaded classification File in the ALV Grid of ZKNSF_CLASSIFICATION_MANAGR?
If you are using the Java GUI (e.g. on MacOS) this is a known issue we can't fix.
See more details in this [Github Issue](https://github.com/SAP/project-kernseife/issues/16)

## Why can't I navigate to the finding object (Error: There is no navigation information available)?
This is a known bug and there is a [Note](https://me.sap.com/notes/3623342) to fix it.
Alternativly you might want to start using ATC in ADT instead of GUI ;)

## Why are there check failures and dumps due to ITAB_DUPLICATE_KEYS?
Please check this [issue](https://github.com/SAP/project-kernseife/issues/19).

## Dump *Function module "RS_ABAP_GET_INTFS_INCL_INFT_E" is not found*

<img width="775" height="691" alt="image" src="https://github.com/user-attachments/assets/f320f761-2102-4311-8b2b-393ecef031e9" />

You most likely forgot to execute the manual step of this [note](https://me.sap.com/notes/3373034) (Predecessor of the ATC Check Note)
```
"Start report RS_ABAP_SETUP_ANALYSIS. You will be asked for transports request.
Please enter the transport request which is used for correction instructions."
```
