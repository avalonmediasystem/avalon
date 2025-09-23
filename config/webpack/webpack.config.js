const path    = require("path")
const TerserPlugin = require('terser-webpack-plugin');
const webpack = require("webpack")
const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';
const isDev = mode === 'development'

module.exports = {
  mode: mode,
  entry: {
    application: '/home/app/avalon/app/javascript/application.js',
    embed: '/home/app/avalon/app/javascript/embed.js',
    'iiif-timeliner': '/home/app/avalon/app/javascript/iiif-timeliner.js',
    'server-bundle': '/home/app/avalon/app/javascript/server-bundle.js',
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
    // with our minimizer settings. We can test minifcation by running `yarn build --progress`
    // in the container then reloading the page after the build finishes.
    minimize: isDev && true,
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
      }),
    ],
    moduleIds: 'deterministic',
  },
  output: {
    filename: (pathData) => {
      return pathData.chunk.name === 'application' ? '[name]_webpack.js' : '[name].js';
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
    modules: ["/home/app/avalon/app/javascript", "node_modules"],
  },
}
