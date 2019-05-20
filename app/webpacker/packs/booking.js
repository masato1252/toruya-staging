import 'babel-polyfill'

var BookingcomponentRequireContext = require.context("../javascripts/components", true, /booking|shared/)
var ReactRailsUJS = require("react_ujs")
ReactRailsUJS.useContext(BookingcomponentRequireContext)

import Rails from 'rails-ujs';
Rails.start();
