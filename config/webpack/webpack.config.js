// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig } = require('shakapacker');
const { merge } = require('webpack-merge');
const webpack = require('webpack');

const webpackConfig = generateWebpackConfig();

const options = {
  resolve: {
    extensions: ['.css'],
    fallback: {
      "buffer": require.resolve("buffer/"),
      "path": require.resolve("path-browserify"),
      "stream": require.resolve("stream-browserify"),
      "util": require.resolve("util/")
    }
  },
  plugins: [
    new webpack.ProvidePlugin({
      process: 'process/browser.js',
    }),
  ],
};

module.exports = merge({}, webpackConfig, options);
