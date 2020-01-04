/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Support component names relative to this directory:
import "core-js/stable";
import "regenerator-runtime/runtime";
import 'jquery'
import 'bootstrap-sass/assets/javascripts/bootstrap'
import './stylesheets.scss';

var componentRequireContext = require.context("../javascripts/components", true, /^\.\/(management|shared)/)
var ReactRailsUJS = require("react_ujs")
ReactRailsUJS.useContext(componentRequireContext)

import "@stimulus/polyfills"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("../javascripts/controllers", true, /.js$/)
application.load(definitionsFromContext(context))

require.context('../assets/management', true)

import Rails from 'rails-ujs';
Rails.start();

// https://github.com/zenorocha/clipboard.js/issues/155#issuecomment-217372642
// Fix ClipboardJS copy in modal
$.fn.modal.Constructor.prototype.enforceFocus = function() {};
