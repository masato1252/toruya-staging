const environment = require('./environment')

// it was disabled by default in PR https://github.com/rails/webpacker/pull/770
// https://github.com/rails/webpacker/issues/769#issuecomment-328452033
// enable sourcemap
const config = environment.toWebpackConfig()
config.devtool = 'source-map'

module.exports = config
