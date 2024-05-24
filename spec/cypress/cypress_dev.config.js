const { defineConfig } = require("cypress");

module.exports = defineConfig({
  env: {
    "USERS_ADMINISTRATOR_EMAIL": "archivist1@example.com",
    "USERS_ADMINISTRATOR_PASSWORD": "archivist1",
    "USERS_USER_EMAIL":"user1@example.com",
    "USERS_USER_PASSWORD": "testing_user1",
    "MEDIA_OBJECT_ID": "fj236208t",
    "MEDIA_OBJECT_TITLE":"Beginning Responsibility: Lunchroom Manners",
    "SEARCH_COLLECTION":"7.7 regression test",
  },
  downloadsFolder: "spec/cypress/downloads",
  fixturesFolder: "spec/cypress/fixtures",
  screenshotsFolder: "spec/cypress/screenshots",
  videosFolder: "spec/cypress/videos",
  browser: process.env.BROWSER || 'electron', //
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    baseUrl: "https://avalon-dev.dlib.indiana.edu/",
    supportFile: "spec/cypress/support/e2e.js",
    specPattern: "spec/cypress/integration/**/*.js"
  },

  
});
