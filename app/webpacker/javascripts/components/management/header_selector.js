"use strict";

import React from "react";
import Select from ".././shared/select.js"

class HeaderSelector extends React.Component {
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
      <Select options={this.props.options}
        name="selectedOption"
        value={this.state.selectedOption}
        onChange={this._handleChange}
      />
    )
  }
};

export default HeaderSelector;
