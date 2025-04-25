sap.ui.define(
  [
  ],
  function () {
    "use strict";

    return {
      downloadMissingClassifications: function () {
        const serviceUrl = this.getModel().getServiceUrl();
        window.open(serviceUrl + "Downloads/missingClassifications", "_blank")
      }
    };
  }
);
