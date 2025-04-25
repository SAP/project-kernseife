sap.ui.require(
    [
        'sap/fe/test/JourneyRunner',
        'configuredefault/test/integration/FirstJourney',
		'configuredefault/test/integration/pages/SettingsList',
		'configuredefault/test/integration/pages/SettingsObjectPage'
    ],
    function(JourneyRunner, opaJourney, SettingsList, SettingsObjectPage) {
        'use strict';
        var JourneyRunner = new JourneyRunner({
            // start index.html in web folder
            launchUrl: sap.ui.require.toUrl('configuredefault') + '/index.html'
        });

       
        JourneyRunner.run(
            {
                pages: { 
					onTheSettingsList: SettingsList,
					onTheSettingsObjectPage: SettingsObjectPage
                }
            },
            opaJourney.run
        );
    }
);