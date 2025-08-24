# Documentation on classification

## Impact of Classification
Ratings define for a SAP object the result in our Kernseife ATC Check. This includes the severity / finding priority (Error/Warning/Information) as well as the "Kernseife" score.
This score can be used to compare custom code objects and to identify the objects with the highest dependency to SAP objects, that you do not want to refer to.

## SAP's sources for classification information
While it might be a benefit to adjust a classification specifically to your usecase, it is useful to start with SAP's official information on classification. We recommend to always check official sources on the release state of SAP objects.

* [Business Accelerator Hub](https://api.sap.com/products/SAPS4HANACloudPrivateEdition/overview) for released APIs and their documentation

* [Cloudification Repository](https://sap.github.io/abap-atc-cr-cv-s4hc/?version=objectReleaseInfo_PCELatest.json) for released objects (of the current PCE version)

* [Cloudification Repository](https://sap.github.io/abap-atc-cr-cv-s4hc/?version=objectClassifications_3TierModel.json) for classic API and "noAPI" objects

## Classification Categories
| Category ID | Category Name | Criticality | Kernseife Points | Clean Core Level* |Description | Example |
| :---------: | :-----------: | :------: | :--------------: | :------: | ----------- | ------- |
| TBL | Database Table | E | 10 | C / D | Database tables will be handled by the ATC check depending on the DB operation that is used: Changing access (e.g. UPDATE, INSERT, DELETE) will be marked as "Error" and "10" Kernseife points, reading access (SELECT) will be handled as warning. | SELECT * FROM MARA will lead to a warning (although there is a successor with I_Product available), UPDATE MARA  |
| BF9 | Business Function - Avoid | E | 9 | D | A business function that is marked as "noAPI" in SAP's cloudification repository (3 Tier File) or customly marked as "not recommended" | BAPI_BUPA_ROLE_ADD (to be replaced by BAPI_BUPA_ROLE_ADD_2)
| FW9 | Framework - Avoid | E | 9 | D | like BF9, but usage of a technical framework that is marked as "noAPI" and should no longer be used at all. | SX_INTERNET_ADDRESS_TO_NORMAL (to be replaced by CL_BCS_EMAIL_ADDRESS) | 
| BF5 | Business Function - Internal | W | 5 | C | A business functionality (e.g. class or function module) that is called, but was never released by SAP. This is not generally recommended. Still, it is "only" a warning as we want to distinguish from the "noAPI" usages.  | Any classes / function modules / ...  like CL_MM_PUR_CNTRL_CTR_MA_MPC | 
| FW5 | Framework - Internal | W | 5 | C | A technical framework (e.g. class or function module) that is called, but was never released by SAP. This is not generally recommended. Still, it is "only" a warning as we want to distinguish from the "noAPI" usages. | Any classes / function modules / ... from technical frameworks, e.g. CL_WDY_MD_VIEW_ELEMENT_DEF | 
| BF3 | Business Function - Utility | I | 3 | B | A business functionality (e.g. class or function module), which is not released but its usage is related to other functionality and is considered good practice (e.g. Exemption Classes, BADI Example Implementations, etc.)  | Exemption classes / BADI Example Implementations / ...  like /SCWM/CX_RESOURCE_MGMT | 
| FW3 | Framework - Utility | I | 3 | B | A technical framework (e.g. class or function module), which is not released but its usage is related to other functionality and is considered good practice (e.g. Exemption Classes, BADI Example Implementations, etc.) | Exemption classes / BADI Example Implementations / like /BOPF/CX_FRW | 
| BF1 | Business Function - Recommended | I | 1 | B | Usage of objects that are nominated by SAP as "Classic API" in the cloudification Repository | BAPI_PO_CREATE1 | 
| FW1 | Framework - Recommended | I | 1 | B | With the introduction of classic APIs in Tier 3, we recognize the technical stability of frameworks. Technical framework objects from the cloudification repository marked as "Classic API" are in this category | CL_SALV* classes | 
| DDC | DDIC - Complex | I | 3 | B/C** | More complex DDIC objects like Table Types or Structures are only measured as "Info" message, but still can come with some dependency to unreleased standard functionality. |  Usage of structures that are not released, e.g. SFPDOCPARAMS  | 
| DDS | DDIC - Simple | I | 1 | B/C** | Simpler DDIC Objects like data elements or domains are considered as "DDIC Simple" findings. The dependency to the core is low, they could often easily be replaced by custom data elements. | DTEL SYUCOMM | 
| MSG | Message Class | I | 1 | B/C** | Message Classes are often leveraged to access the same messages as SAP standard uses. These might not be released but are typically considered stable. | Any Message Class you are using | 
| ENH | BADI | I | 0 | B | Usages of BADIs that are not released for ABAP Cloud are only marked as Info message as we consider these as upgrade stable as their ABAP Cloud released counterparts |  | 
| BF0 | Business Function - Released | S | 0 | A | Any business functionality you can use as it is officially released for the usage in ABAP Cloud | Released CDS Views like I_Product or released business object interfaces like BDEF 'I_PRODUCTTP_2'  | 
| FW0 | Framework - Released | S | 0 | A | SAP Objects for the usage of technical frameworks / reuse components that are officially released for the use in ABAP Cloud | Classes like 'CL_ABAP_FORMAT'. |
| NOC | Missing Classification | E | 0 | C | Objects that are not yet in your classification file will be considered as "NOC" classification. We recommend to have this as error to be aware of objects you have not yet identified through ATC. | - | 

Explanation *: Clean Core Levels are officially described in the [Whitepaper for Clean Core Extensibility](https://www.sap.com/documents/2024/09/20aece06-d87e-0010-bca6-c68f7e60039b.html). The official level to ATC-mapping for the standard check variant (from Note 3565942) is described in chapter 5.1.2 of the [ABAP Extensibility Document](https://www.sap.com/documents/2022/10/52e0cd9b-497e-0010-bca6-c68f7e60039b.html). With Kernseife, you can adjust the behavior to your requirements (and e.g., define a class as "classic API" that is not officially nominated by SAP) - but please be aware that this flexibility possibly includes  differences between your official scoring (based on standard ATC checks) and your Kernseife scoring.

Explanation **: As the standard ATC check is focussing on the object types that are used for classic APIs, DDIC objects (like DTEL, Structures, TTYP, ...) are not considered in the official check. If the structure is needed to call a classic API (e.g. SFPDOCPARAMS for function module FP_JOB_OPEN or the subsequent form calls), you could consider it as "classic API". If it is not connected to a classic API, it can be seen as "Internal Object". As the main dependency in this case would be reflected in calling the classic API, Kernseife default score is relatively low to avoid too many "important" messages.
