"use strict";

import "./shared/select.js"
import React from "react";

var createReactClass = require('create-react-class');

UI.define("HeaderSelector", function() {
  var HeaderSelector = createReactClass({
    getInitialState: function() {
      return {
        selectedOption: this.props.selectedOption,
      }
    },

    _handleChange: function(event) {
      this.setState({[event.target.name]: event.target.value});
      var shopPathRegexp = /shops\/([^\/]+)/;

      if (this.props.isShopSelector) {
        if (location.pathname.match(shopPathRegexp)) {
          var newLocation = location.href.replace(shopPathRegexp, `shops/${event.target.value}`)
          location = newLocation;
        }
      }
      else {
        var newLocation = `${location.protocol}//${location.hostname}${location.pathname}?staff_id=${event.target.value}`;
        location = newLocation;
      }
    },

    render: function() {
      if (!this.props.options) { return null }

      return (
        <UI.Select options={this.props.options}
          name="selectedOption"
          value={this.state.selectedOption}
          onChange={this._handleChange}
        />
      )
    }
  });

  return HeaderSelector;
});

export default UI.HeaderSelector;
