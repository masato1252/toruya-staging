import 'babel-polyfill'

var BookingcomponentRequireContext = require.context("../javascripts/components", true, /^\.\/(booking|shared)/)
var ReactRailsUJS = require("react_ujs")
ReactRailsUJS.useContext(BookingcomponentRequireContext)

import "@stimulus/polyfills"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import './booking_stylesheets.scss';

const application = Application.start()
const context = require.context("../javascripts/controllers", true, /^\.\/(collapse)/)
application.load(definitionsFromContext(context))

require.context('../assets/booking', true)

import Rails from 'rails-ujs';
Rails.start();
