const { defineConfig } = require("cypress");

module.exports = defineConfig({
  downloadsFolder: "spec/cypress/downloads",
  fixturesFolder: "spec/cypress/fixtures",
  screenshotsFolder: "spec/cypress/screenshots",
  videosFolder: "spec/cypress/videos",
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    baseUrl: "http://localhost:3000",
    supportFile: "spec/cypress/support/e2e.js",
    specPattern: "spec/cypress/integration/**/*.js"
  },
});
