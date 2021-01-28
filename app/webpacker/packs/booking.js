import "core-js/stable";
import "regenerator-runtime/runtime";
import Routes from '../js-routes.js';
import I18n from 'i18n-js/index.js.erb';

var BookingcomponentRequireContext = require.context("../javascripts/components", true, /^\.\/(booking|shared|lines|user_bot\/sales|user_bot\/services)/)
var ReactRailsUJS = require("react_ujs")
ReactRailsUJS.useContext(BookingcomponentRequireContext)

import "@stimulus/polyfills"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("../javascripts/controllers", true, /^\.\/(collapse|line_user_redirector)/)
application.load(definitionsFromContext(context))

require.context('../assets/booking', true)

window.Routes = Routes;
window.I18n = I18n;

import Rails from 'rails-ujs';
Rails.start();
