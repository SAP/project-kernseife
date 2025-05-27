# How to install the Kernseife BTP App

## Prerequisits
* BTP Sub-Account with Cloud Foundry enabled
* min. 2 GB of Application Runtime
* A *HANA Cloud* instance which can be used for a HDI Container
* Following Services (Technical Service Name):
    * SAP HANA Schemas & HDI Containers (hana) - Plan: hdi-shared
    * Authorization and Trust Management Service (xsuaa) - Plan: application (Always Free)
    * HTML5 Application Repository Service (html5-apps-repo) - Plan: app-host (Always Free)
    * Destination Service (destination) - Plan: lite (Always Free)
    * Application Autoscaler (autoscaler) - Plan: standard (Always Free)
    * Cloud Logging (cloud-logging) - Plan: dev (Use Plan "standard" for Production)<br/>
The old Applicating Logging Service could also be used, but as Cloud Logging is the successor.<br/>
See more here https://community.sap.com/t5/technology-blog-posts-by-sap/from-application-logging-to-cloud-logging-service-innovation-guide/ba-p/13938380
