const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const isWebpackDevServer = process.argv.some(a => path.basename(a) === 'webpack-dev-server');
const isWatch = process.argv.some(a => a === '--watch');

module.exports = {
  entry: './plground/index.js',
  module: {
    rules: [
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.purs$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'purs-loader',
            options: {
              spago: true,
              pscIde: true,
              watch: isWebpackDevServer || isWatch,
            },
          },
        ],
      },
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({ template: './plground/index.html' }),
  ],
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
};
