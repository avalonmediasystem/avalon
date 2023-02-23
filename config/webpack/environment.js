const { environment } = require('@rails/webpacker')

// Preventing Babel from transpiling NodeModules packages
environment.loaders.delete('nodeModules');

module.exports = environment
