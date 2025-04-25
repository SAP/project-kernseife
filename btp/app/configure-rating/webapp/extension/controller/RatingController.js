sap.ui.define([], function () {
  "use strict";

  return {
    downloadRatingConfigDefault: function () {
      const serviceUrl = this.getModel().getServiceUrl().replace("odata/v4/admin/", "").replace("configure-rating/webapp/", "");
      window.open(serviceUrl + "download?type=RatingConfigDefault", "_blank");
    },
    downloadRatingConfigLegacy: function () {
      const serviceUrl = this.getModel().getServiceUrl().replace("odata/v4/admin/", "").replace("configure-rating/webapp/", "");
      window.open(serviceUrl + "download?type=RatingConfigLegacy", "_blank");
    },
  };
});
