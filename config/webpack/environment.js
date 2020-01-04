const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    jquery: 'jquery'
  })
)

// https://stackoverflow.com/a/10729284/609365
// print final webpack.config.js content
const util = require('util')
console.log(util.inspect(environment, false, null, true /* enable colors */))

module.exports = environment
