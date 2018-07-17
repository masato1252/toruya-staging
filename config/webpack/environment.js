const { environment } = require('@rails/webpacker')
const erb =  require('./loaders/erb')

environment.loaders.set('erb', erb)
module.exports = environment
