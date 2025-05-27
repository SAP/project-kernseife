sap.ui.define(
  [
    "sap/m/MessageBox",
    "sap/m/MessageToast",
    "sap/ui/unified/FileUploaderParameter",
  ],
  function (MessageBox, MessageToast, FileUploaderParameter) {
    "use strict";

    const _createUploadController = function (oExtensionAPI, oUploadType) {
      let oUploadDialog;

      const setOkButtonEnabled = function (bOk) {
        oUploadDialog && oUploadDialog.getBeginButton().setEnabled(bOk);
      }

      const setDialogBusy = function (bBusy) {
        oUploadDialog.setBusy(bBusy);
      }

      const closeDialog = function () {
        oUploadDialog && oUploadDialog.close();
      }

      const showError = function (sMessage) {
        MessageBox.error(sMessage || "Upload failed");
      }

      const byId = function (sId) {
        return sap.ui.core.Fragment.byId("uploadDialog", sId);
      }

      return {
        onBeforeOpen: function (oEvent) {
          oUploadDialog = oEvent.getSource();
          oExtensionAPI.addDependent(oUploadDialog);
        },

        onAfterClose: function (oEvent) {
          oExtensionAPI.removeDependent(oUploadDialog);
          oUploadDialog.destroy();
          oUploadDialog = undefined;
        },

        onOk: function (oEvent) {
          setDialogBusy(true);

          const oFileUploader = byId("uploader");

          const serviceUrl = oExtensionAPI.getModel().getServiceUrl() + "FileUpload/file";

          oFileUploader.setUploadUrl(serviceUrl);
          oFileUploader.destroyHeaderParameters();

          const xCrsrfToken = new FileUploaderParameter();
          xCrsrfToken.setName("X-CSRF-Token");
          xCrsrfToken.setValue(
            oExtensionAPI.getModel().getHttpHeaders()["X-CSRF-Token"]
          );
          oFileUploader.addHeaderParameter(xCrsrfToken);

          const uploadType = new FileUploaderParameter();
          uploadType.setName("X-Upload-Type");
          uploadType.setValue(oUploadType);
          oFileUploader.addHeaderParameter(uploadType);

          const fileName = new FileUploaderParameter();
          fileName.setName("X-File-Name");
          fileName.setValue(oFileUploader.getValue());
          oFileUploader.addHeaderParameter(fileName);

          oFileUploader
            .checkFileReadable()
            .then(function () {
              oFileUploader.upload();
            })
            .catch(function (error) {
              showError("The file cannot be read.");
              setDialogBusy(false);
            });
        },

        onCancel: function (oEvent) {
          closeDialog();
        },

        onTypeMismatch: function (oEvent) {
          const sSupportedFileTypes = oEvent
            .getSource()
            .getFileType()
            .map(function (sFileType) {
              return "*." + sFileType;
            })
            .join(", ");

          showError(
            "The file type *." +
            oEvent.getParameter("fileType") +
            " is not supported. Choose one of the following types: " +
            sSupportedFileTypes
          );
        },

        onFileAllowed: function (oEvent) {
          setOkButtonEnabled(true);
        },

        onFileEmpty: function (oEvent) {
          setOkButtonEnabled(false);
        },

        onUploadComplete: function (oEvent) {
          const iStatus = oEvent.getParameter("status");
          const oFileUploader = oEvent.getSource();

          oFileUploader.clear();
          setOkButtonEnabled(false);
          setDialogBusy(false);

          if (iStatus >= 400) {
            const oRawResponse = JSON.parse(oEvent.getParameter("responseRaw"));
            showError(
              oRawResponse && oRawResponse.error && oRawResponse.error.message
            );
          } else {
            MessageToast.show("Uploaded successfully");
            oExtensionAPI.refresh();
            closeDialog();
          }
        },
      };
    }

    return {
      showUploadClassificationDialog: function () {
        this.loadFragment({
          id: "uploadDialog",
          name: "manageclassification.extension.fragment.UploadClassificationsDialog",
          controller: _createUploadController(this, "Classifications"),
        }).then(function (oDialog) {
          oDialog.open();
        });
      },
      downloadClassificationStandard: function () {
        const serviceUrl = this.getModel().getServiceUrl();
        window.open(serviceUrl + "Downloads/classificationStandard", "_blank")
      },
      downloadClassificationCustom: function () {
        const serviceUrl = this.getModel().getServiceUrl();
        window.open(serviceUrl + "Downloads/classificationCustom", "_blank")
      },
      downloadClassificationCloud: function () {
        const serviceUrl = this.getModel().getServiceUrl();
        window.open(serviceUrl + "Downloads/classificationCloud", "_blank")
      },
      downloadClassificationGithub: function () {
        const serviceUrl = this.getModel().getServiceUrl();
        window.open(serviceUrl + "Downloads/classificationGithub", "_blank")
      },
      
    };
  }
);
