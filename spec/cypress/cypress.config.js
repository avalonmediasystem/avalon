const { defineConfig } = require("cypress");

module.exports = defineConfig({
  env: {
    "USERS_ADMINISTRATOR_EMAIL": "administrator@example.com",
    "USERS_ADMINISTRATOR_PASSWORD": "password",
    "USERS_USER_EMAIL": "user@example.com",
    "USERS_USER_PASSWORD": "password",
    "MEDIA_OBJECT_ID": "123456789"
  },
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
