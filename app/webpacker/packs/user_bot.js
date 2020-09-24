import "core-js/stable";
import "regenerator-runtime/runtime";
import Routes from '../js-routes.js';

var BookingcomponentRequireContext = require.context("../javascripts/components", true, /^\.\/(user_bot)/)
var ReactRailsUJS = require("react_ujs")
ReactRailsUJS.useContext(BookingcomponentRequireContext)

import "@stimulus/polyfills"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("../javascripts/controllers", true, /^\.\/(line_user_redirector)/)
application.load(definitionsFromContext(context))

require.context('../assets/user_bot', true)

window.Routes = Routes;

import Rails from 'rails-ujs';
Rails.start();
