sap.ui.define(
    ["sap/fe/core/AppComponent"],
    function (Component) {
        "use strict";

        return Component.extend("configuredefault.Component", {
            metadata: {
                manifest: "json"
            },
            init: function (...args) {
                Component.prototype.init.apply(this, ...args);
                this.getRouter().navTo("SettingsObjectPage", { key: "ID=1,IsActiveEntity=true" }, true);
            }
        });
    }
);