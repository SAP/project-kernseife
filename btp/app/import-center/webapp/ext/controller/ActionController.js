sap.ui.define(
  [
    'sap/m/MessageBox',
    'sap/m/MessageToast',
    'sap/ui/unified/FileUploaderParameter'
  ],
  function (MessageBox, MessageToast, FileUploaderParameter) {
    'use strict';

    const _createUploadController = (oExtensionAPI) => {
      let oUploadDialog;

      const setOkButtonEnabled = function (bOk) {
        oUploadDialog && oUploadDialog.getBeginButton().setEnabled(bOk);
      };

      const setDialogBusy = function (bBusy) {
        oUploadDialog.setBusy(bBusy);
      };

      const closeDialog = function () {
        oUploadDialog && oUploadDialog.close();
      };

      const showError = function (sMessage) {
        MessageBox.error(sMessage || 'Upload failed');
      };

      const byId = function (sId) {
        return sap.ui.core.Fragment.byId('uploadDialog', sId);
      };

      const setFieldVisibility = function (id, visibility) {
        const label = byId('label' + id.charAt(0).toUpperCase() + id.slice(1));
        if (label) label.setVisible(visibility);

        const field = byId(id);
        field.setVisible(visibility);
      };

      const setFileEndings = function (fileEndings) {
          console.log('File Endings:', fileEndings);
        const oFileUploader = byId('uploader');
        if (fileEndings) {
          const fileTypes = fileEndings
            .split(',')
            .map(function (sFileEnding) {
              return sFileEnding.trim();
            });
            console.log('File types:', fileTypes);
          oFileUploader.setFileType(fileTypes);
        } else {
          oFileUploader.setFileType([]);
        }
      };

      const onChange = function (oEvent) {
        // Get Value
        const showSystemId = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().reqSystemId;
        setFieldVisibility('systemId', showSystemId);
        const showDefaultRating = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().defaultRating;
        setFieldVisibility('defaultRating', showDefaultRating);

        const showComment = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().comment;
        setFieldVisibility('comment', showComment);

        setFieldVisibility('uploader', true);

        const fileEndings = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().fileEndings;
        setFileEndings(fileEndings);
      };

      return {
        onChange,
        onBeforeOpen: function (oEvent) {
          oUploadDialog = oEvent.getSource();
          oExtensionAPI.addDependent(oUploadDialog);

          setFieldVisibility('systemId', false);
          setFieldVisibility('defaultRating', false);
          setFieldVisibility('comment', false);
          setFieldVisibility('uploader', false);
          setFileEndings('');
        },

        onAfterClose: function (oEvent) {
          oExtensionAPI.removeDependent(oUploadDialog);
          oUploadDialog.destroy();
          oUploadDialog = undefined;
        },

        onOk: function (oEvent) {
          setDialogBusy(true);

          const oFileUploader = byId('uploader');
          const serviceUrl =
            oExtensionAPI.getModel().getServiceUrl() + 'FileUpload/file';

          oFileUploader.setUploadUrl(serviceUrl);
          oFileUploader.destroyHeaderParameters();

          const xCrsrfToken = new FileUploaderParameter();
          xCrsrfToken.setName('X-CSRF-Token');
          xCrsrfToken.setValue(
            oExtensionAPI.getModel().getHttpHeaders()['X-CSRF-Token']
          );
          oFileUploader.addHeaderParameter(xCrsrfToken);

          const uploadType = new FileUploaderParameter();
          uploadType.setName('X-Upload-Type');
          uploadType.setValue(byId('importType').getSelectedKey());
          oFileUploader.addHeaderParameter(uploadType);

          const fileName = new FileUploaderParameter();
          fileName.setName('X-File-Name');
          fileName.setValue(oFileUploader.getValue());
          oFileUploader.addHeaderParameter(fileName);

          const systemId = new FileUploaderParameter();
          systemId.setName('X-System-Id');
          systemId.setValue(byId('systemId').getSelectedKey());
          oFileUploader.addHeaderParameter(systemId);

          const defaultRating = new FileUploaderParameter();
          defaultRating.setName('X-Default-Rating');
          defaultRating.setValue(byId('defaultRating').getSelectedKey());
          oFileUploader.addHeaderParameter(defaultRating);

          const comment = new FileUploaderParameter();
          comment.setName('X-Comment');
          comment.setValue(byId('comment').getValue());
          oFileUploader.addHeaderParameter(comment);

          oFileUploader
            .checkFileReadable()
            .then(function () {
              oFileUploader.upload();
            })
            .catch(function (error) {
              showError('The file cannot be read.');
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
              return '*.' + sFileType;
            })
            .join(', ');

          showError(
            'The file type *.' +
              oEvent.getParameter('fileType') +
              ' is not supported. Choose one of the following types: ' +
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
          const iStatus = oEvent.getParameter('status');
          const oFileUploader = oEvent.getSource();

          oFileUploader.clear();
          setOkButtonEnabled(false);
          setDialogBusy(false);

          if (iStatus >= 400) {
            const oRawResponse = JSON.parse(oEvent.getParameter('responseRaw'));
            showError(
              oRawResponse && oRawResponse.error && oRawResponse.error.message
            );
          } else {
            MessageToast.show('Uploaded successfully');
            oExtensionAPI.refresh();
            closeDialog();
          }
        }
      };
    };

    return {
      showUploadDialog: function (oEvent) {
        this.loadFragment({
          id: 'uploadDialog',
          name: 'importcenter.ext.fragment.UploadDialog',
          controller: _createUploadController(this)
        }).then(function (oDialog) {
          oDialog.open();
        });
      }
    };
  }
);
