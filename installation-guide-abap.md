# How to install the Kernseife ATC Check

## Prerequisits
* ABAP Test Cockpit (ATC) on a system with SAP S/4HANA 2023 (or higher)

* As this check is based on the "3-Tier Model" Check, it is necessary to have [SAP Note 3565942](https://me.sap.com/notes/3565942) implemented in your system.
  The current Implementation is tested with v14 of the note. Lower versions will not work out of the box and might need some code adjustments.

* Kernseife Classification JSON File

* Authorizations
All which is included in the Standard Role: SAP_SATC_QE
Additionally: SYCM_API
![image](https://github.com/user-attachments/assets/4eb94ebd-5c31-4090-8a81-a1bc5790d295)

* Workbench Transport Request.

* Latest release from the [Release Page](https://github.com/SAP/project-kernseife/releases/latest) (.zip file)

## Import the Kernseife ATC Check into target system (using [abapGit](https://github.com/abapGit/abapGit))
Run the standalone version of abapGit using transaction `ZABAPGIT` or executing the report in ZABAPGIT_STANDALONE.
![image](https://github.com/user-attachments/assets/16fd20d4-7dab-4d4a-8741-e149f2085195)
You can find the lastest version of the standalone report here: https://raw.githubusercontent.com/abapGit/build/main/zabapgit_standalone.prog.abap

In abapGit click on "New Offline" to add a new repository. Enter the repo name KERNSEIFE and create a new package $KERNSEIFE and click on "Create Offline Repository".
![image](https://github.com/user-attachments/assets/234f439e-c64d-41fa-81e5-d1453dbeb13a)
![image](https://github.com/user-attachments/assets/4c9dcb0c-9c05-4aa5-abfd-0b7a82e9a29f)

In the new offline repository click on "Import zip" and upload the file from the [Release Page](https://github.com/SAP/project-kernseife/releases/latest)

![image](https://github.com/user-attachments/assets/7f1267c2-88e5-4723-82a1-5d82caa01f10)

After the .zip was imported you need to press "Pull". This opens a dialog where you have to confirm the objects to be imported. 
If you used the Package name starting with $, it will be a Local Package and no transport is needed.
Otherwise you need a Workbench Transport Request.
As we normally don't want to run code-checks in Quality or Production, we recommend using a Local Package.

## Enable Kernseife Check Variant for ATC
After importing the the repository and creating the configuration files, the ATC check must be imported in ABAP Code inspector.
Open Transaction `SCI` (Code Inspector) and click in the top bar on Utilities => "Import Check Variants"
![image](https://github.com/user-attachments/assets/aa0658c1-f468-4082-a3a7-219aa845b263)


After that you can confirm the succesfull import by clicking on "Code Inspector => Management of => Checks". 

![image](https://github.com/user-attachments/assets/f635b3fc-fc17-4bc3-8ea8-e4277f7343e5)

The checks for Kernseife should now appear in this list.
First you need to select the Category (ZKNSF_CL_CI_CATEGORY) and save.
Afterwards you can select the Check (ZKNSF_CL_API_USAGE) and save.
This requires a Workbench Request which can be deleted afterwards, in case you don't want to transport the Checks downstream.

## Upload Classification Json
Execute Report ZKNSF_CLASSIFICATION_MANAGR
![image](https://github.com/user-attachments/assets/07e5d511-1d64-4edf-a83a-4d8b2f3f05a0)

Click on "Upload Classic API File".
Select the Classification Json File.

As the main purpose is to create a custom classification, we encourage you to leverage the CAP application to create a classification JSON file according to your needs. Still, we offer a [default classification file](https://raw.githubusercontent.com/SAP/project-kernseife/refs/heads/main/defaultClassification.json).
**Remark:** This file is purely based on the Cloudification Repository as of 2025-05-21. It is not the "best" or "right" classification, but a starting point that you can begin your Kernseife installation.

## Create Check Variant

Go to Transaction SCI and create a new check variant.
We recommend to copy the standard variant ABAP_CLOUD_DEVELOPMENT_3TIER as a base.
Make sure the new Variant is a public one and not a personal one.

<img width="420" alt="image" src="https://github.com/user-attachments/assets/46166da6-90f7-4407-a651-595961e2ee5e" />


If you used ABAP_CLOUD_DEVELOPMENT_3TIER, you should
Disable the "Usage of Released APIs" Check.
Enable the "Check for Enhancement Technology".

In every case you need to activate the "Kernseife: Usage of APIs" Check.

![image](https://github.com/user-attachments/assets/e9ad498f-52fa-45c0-85ea-73ef50119ca4)

Congratulations, you are now able to use the Kernseife ATC Check.
