import "core-js/stable";
import "regenerator-runtime/runtime";
import 'jquery'
import 'bootstrap-sass/assets/javascripts/bootstrap'
import Routes from '../js-routes.js';
import I18n from 'i18n-js/index.js.erb';
import toastr from 'toastr';

var BookingcomponentRequireContext = require.context("../javascripts/components", true, /^\.\/(user_bot|management|shared|line_notice_requests)/)
var ReactRailsUJS = require("react_ujs")
ReactRailsUJS.useContext(BookingcomponentRequireContext)

import "@stimulus/polyfills"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("../javascripts/controllers", true, /.js$/)
application.load(definitionsFromContext(context))

require.context('../assets/user_bot', true)

window.toastr = toastr;
window.Routes = Routes;
window.I18n = I18n;

import Rails from 'rails-ujs';
Rails.start();
