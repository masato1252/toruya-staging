const { environment } = require('@rails/webpacker')
const webpack = require('webpack')
const erb = require('./loaders/erb')

environment.loaders.prepend('erb', erb)
environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader',
});

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    jquery: 'jquery'
  })
)

module.exports = environment
