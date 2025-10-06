const path    = require("path")
const TerserPlugin = require('terser-webpack-plugin');
const webpack = require("webpack")

module.exports = (env, argv) => {
  const isProd = argv.mode === 'production';

  const config = {
    mode: argv.mode,
    devtool: isProd ? false : 'eval-source-map',
    entry: {
      application: path.resolve(__dirname, '..', '..', 'app/javascript/application.js'),
      embed: path.resolve(__dirname, '..', '..', 'app/javascript/embed.js'),
      'iiif-timeliner': path.resolve(__dirname, '..', '..', 'app/javascript/iiif-timeliner.js'),
      'server-bundle': path.resolve(__dirname, '..', '..', 'app/javascript/server-bundle.js'),
    },
    module: {
      rules: [
        {
          test: /\.css$/,
          use: [
            'style-loader',
            'css-loader',
          ]
        },
        {
          test: /\.scss$/,
          use: [
            'style-loader',
            'css-loader',
            {
              loader: 'sass-loader',
              options: {
                api: 'modern',
              },
            }
          ]
        },
        {
          test: /\.(js|jsx)$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
          }
        }
      ]
    },
    optimization: {
      // Development mode has much quicker compile and rebuild times, however does not play well
      // with the minimizer. 
      minimize: isProd,
      minimizer: [
        new TerserPlugin({
          terserOptions: {
            format: {
              ascii_only: true,
              inline_script: false,
              max_line_len: 32 * 1024,
            },
            mangle: {
              // These options are necessary for SME to build properly. Unsure what the exact problem
              // is, but something with SME was breaking the mangle operation and causing .5 MB of JS to be lost.
              keep_classnames: true,
              keep_fnames: true,
              // This option is present in the terser-ruby gem, so preserving it here
              reserved: ['$super'],
            },
            compress: {
              hoist_funs: true,
              collapse_vars: false,
              reduce_funcs: false,
              reduce_vars: false,
              pure_getters: false,
              keep_fargs: false,
              passes: 1,
            },
          },
          parallel: false,
        }),
      ],
      moduleIds: 'deterministic',
    },
    output: {
      filename: (pathData) => {
        return pathData.chunk.name === 'application' ? '[name]_bundle.js' : '[name].js';
      },
      chunkFilename: "[name]-[contenthash].digested.js",
      sourceMapFilename: "[file]-[fullhash].map",
      path: path.resolve(__dirname, '..', '..', 'app/assets/builds'),
      hashFunction: "sha256",
      hashDigestLength: 64,
    },
    plugins: [
      new webpack.optimize.LimitChunkCountPlugin({
        maxChunks: 1
      }),
    ],
    resolve: {
      extensions: ['.js', '.jsx'],
      modules: [path.resolve(__dirname, '..', '..', 'app/javascript'), "node_modules"],
    },
  };

  return config;
}
