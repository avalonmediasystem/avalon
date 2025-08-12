/**
 * Utility helper to compute paths based on Cypress configuration.
 *
 * All paths derive from the values set in cypress.config.js (fixturesFolder, downloadsFolder, etc.).
 */
export function getFixturePath(fileName) {
  // Cypress.config('fixturesFolder') === absolute path to your fixtures folder
  return `${Cypress.config('fixturesFolder')}/${fileName}`;
}

export function getDownloadPath(fileName) {
  return `${Cypress.config('downloadsFolder')}/${fileName}`;
}
