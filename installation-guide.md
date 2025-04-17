# How to install the Kernseife ATC Check

## Prerequisits
A Kernseife Classification Json File

Authorizations: 
All which is included in the Standard Role: SAP_SATC_QE
Additionally: SYCM_API
![image](https://github.com/user-attachments/assets/4eb94ebd-5c31-4090-8a81-a1bc5790d295)

A workbench Transport Request.

Download the latest release from the Release Page (.zip file)

## Import the Kernseife ATC Check into target system (using [abapGit](https://github.com/abapGit/abapGit))
Run the standalone version of abapGit using transaction `ZABAPGIT` or executing the report in ZABAPGIT_STANDALONE.
![image](https://github.com/user-attachments/assets/16fd20d4-7dab-4d4a-8741-e149f2085195)
You can find the lastest version of the standalone report here: https://raw.githubusercontent.com/abapGit/build/main/zabapgit_standalone.prog.abap

In abapGit click on "New Offline" to add a new repository. Enter the repo name KERNSEIFE and create a new package $KERNSEIFE and click on "Create Offline Repository".
![image](https://github.com/user-attachments/assets/234f439e-c64d-41fa-81e5-d1453dbeb13a)
![image](https://github.com/user-attachments/assets/4c9dcb0c-9c05-4aa5-abfd-0b7a82e9a29f)

In the new offline repository click on "Import zip".

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

Now you are able to use the Kernseife ATC Check.

## Create Check Variant

Go to Transaction SCI and create a new check variant.
We recommend to copy the standard variant ABAP_CLOUD_DEVELOPMENT_3TIER as a base.
Make sure the new Variant is a public one and not a personal one.

![image](https://github.com/user-attachments/assets/5046e9fd-9a35-4297-b888-0b9278251272)

If you used ABAP_CLOUD_DEVELOPMENT_3TIER, you should
Disable the "Usage of Released APIs" Check.
Enable the "Check for Enhancement Technology".

In every case you need to activate the "Kernseife: Usage of APIs" Check.

![image](https://github.com/user-attachments/assets/e9ad498f-52fa-45c0-85ea-73ef50119ca4)
