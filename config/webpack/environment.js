const { environment, config } = require('@rails/webpacker')
const erb = require('./loaders/erb')
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

const path = require("path")

// config.source_path: app/webpacker
environment.config.merge({
  resolve: {
    alias: {
      shared: path.resolve(config.source_path, 'javascripts/components/shared'),
      libraries: path.resolve(config.source_path, 'javascripts/libraries'),
      context: path.resolve(config.source_path, 'javascripts/context'),
      components: path.resolve(config.source_path, 'javascripts/components'),
    }
  }
})

environment.splitChunks()
environment.loaders.prepend('erb', erb)
module.exports = environment
