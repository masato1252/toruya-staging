"use strict";

import "./shared/select.js"
import React from "react";

UI.define("HeaderSelector", function() {
  return class HeaderSelector extends React.Component {
    state = {
      selectedOption: this.props.selectedOption,
    };

    _handleChange = (event) => {
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
    };

    render() {
      if (!this.props.options) { return null }

      return (
        <UI.Select options={this.props.options}
          name="selectedOption"
          value={this.state.selectedOption}
          onChange={this._handleChange}
        />
      )
    }
  };
});

export default UI.HeaderSelector;
