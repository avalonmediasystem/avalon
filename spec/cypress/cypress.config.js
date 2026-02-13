const { defineConfig } = require('cypress');
const path = require('path');
const fs = require('fs');

// Determine which env file to load
const environmentName = process.env.CYPRESS_ENV || 'local';
const envFilename = `cypress.env.${environmentName}.json`;
const envPath = path.resolve(__dirname, envFilename);
let envSettings = {};
if (fs.existsSync(envPath)) {
  envSettings = require(envPath);
}
// PROJECT_ROOT in each env file controls where specs, fixtures,etc
const projectRoot = envSettings.env?.PROJECT_ROOT || '';

module.exports = defineConfig({
  downloadsFolder: path.resolve(__dirname, projectRoot, 'downloads'),
  fixturesFolder: path.resolve(__dirname, projectRoot, 'fixtures'),
  screenshotsFolder: path.resolve(__dirname, projectRoot, 'screenshots'),
  videosFolder: path.resolve(__dirname, projectRoot, 'videos'),
  browser: process.env.BROWSER || 'electron',

  e2e: {
    defaultCommandTimeout: 100000, //timeout
    pageLoadTimeout: 100000,
    viewportWidth: 1366,
    viewportHeight: 768,

    setupNodeEvents(on, config) {
      //node env variables
      const environmentName = process.env.CYPRESS_ENV || 'local';
      const environmentFilename = `cypress.env.${environmentName}.json`;
      const environmentPath = path.resolve(__dirname, environmentFilename);
      console.log('Environment name: %s', environmentName);
      console.log('Environment path: %s', environmentPath);

      require('@bahmutov/cy-grep/src/plugin')(config);
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
        console.error(
          `Environment config file ${environmentFilename} not found`
        );
      }
      if (process.env.grepTags) {
        config.env.grepTags = process.env.grepTags;
      }
      return config;
    },

    // Derive support file & spec pattern from projectRoot
    supportFile: path.resolve(__dirname, projectRoot, 'support', 'e2e.js'),
    specPattern: path.resolve(
      __dirname,
      projectRoot,
      'integration',
      '**',
      '*.js'
    ),
  },
});
