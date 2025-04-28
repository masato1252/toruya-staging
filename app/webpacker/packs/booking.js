import "core-js/stable";
import "regenerator-runtime/runtime";
import 'bootstrap-sass/assets/javascripts/bootstrap'
import Routes from '../js-routes.js';
import I18n from 'i18n-js/index.js.erb';
import ahoy from "ahoy.js";
import toastr from 'toastr';

var BookingcomponentRequireContext = require.context("../javascripts/components", true, /^\.\/(booking|surveys|shared|lines|user_bot\/sales|user_bot\/services|user_bot\/user_sign_up|user_bot\/user_connect)/)
var ReactRailsUJS = require("react_ujs")
ReactRailsUJS.useContext(BookingcomponentRequireContext)

import "@stimulus/polyfills"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("../javascripts/controllers", true, /^\.\/(collapse|line_user_redirector)/)
application.load(definitionsFromContext(context))

require.context('../assets/booking', true)

window.toastr = toastr;
window.Routes = Routes;
window.I18n = I18n;

import Rails from 'rails-ujs';
Rails.start();
