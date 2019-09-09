const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const htmlWebpackPlugin = new HtmlWebpackPlugin({
  template: path.join(__dirname, '../../app/javascript/components/collection_view.html'),
  filename: './index.html'
});
module.exports = {
  entry: path.join(__dirname, '../../app/javascript/components/collection_view.js'),
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        use: {
          loader: 'babel-loader'
        },
        exclude: /node_modules/
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      }
    ]
  },
  plugins: [htmlWebpackPlugin],
  resolve: {
    extensions: ['.js', '.jsx']
  },
  devServer: {
    port: 30010,
    open: true
  },
  devtool: 'source-map'
};