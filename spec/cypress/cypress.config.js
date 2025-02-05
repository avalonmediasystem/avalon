const { defineConfig } = require("cypress");
const path = require('path');
const fs = require('fs');

module.exports = defineConfig({

  downloadsFolder: "spec/cypress/downloads",
  fixturesFolder: "spec/cypress/fixtures",
  screenshotsFolder: "spec/cypress/screenshots",
  videosFolder: "spec/cypress/videos",
  browser: process.env.BROWSER || 'electron', //
  e2e: {
    defaultCommandTimeout: 100000, // 10 seconds for command timeouts
    pageLoadTimeout: 100000,
    viewportWidth: 1366,  // Adjust these values as per your application
    viewportHeight: 768,
    setupNodeEvents(on, config) {

      // implement node event listeners here
      const environmentName = process.env.CYPRESS_ENV || 'dev';
      const environmentFilename = `cypress.env.${environmentName}.json`;
      const environmentPath = path.resolve(__dirname, environmentFilename);
      console.log('Environment name: %s', environmentName);
      console.log('Environment path: %s', environmentPath);

      if (fs.existsSync(environmentPath)) {
        console.log('Loading %s', environmentFilename);
        const settings = require(environmentPath);

        // Set baseUrl if defined in the environment settings
        if (settings.baseUrl) {
          config.baseUrl = settings.baseUrl;
          console.log('Loading the baseURL....  %s', config.baseUrl);
        }

        // Merge environment variables
        if (settings.env) {
          config.env = {
            ...config.env,
            ...settings.env,
          };
        }

        console.log('Loaded settings for environment %s', environmentName);
      } else {
        console.error(`Environment config file ${environmentFilename} not found`);
      }
      return config;
    },

    supportFile: "spec/cypress/support/e2e.js",
    specPattern: "spec/cypress/integration/**/*.js"
  },

});
