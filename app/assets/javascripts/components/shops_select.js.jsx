//= require "components/shared/select"

"use strict";

UI.define("ShopsSelect", function() {
  var ShopsSelect = React.createClass({
    getInitialState: function() {
      return {
        selectedShop: this.props.selectedShop
      }
    },

    _handleChange: function(event) {
      this.setState({[event.target.name]: event.target.value});
      window.location.href = event.target.value;
    },

    render: function() {
      if (!this.props.shops.length) { return null }

      return (
        <UI.Select options={this.props.shops}
          name="selectedShop"
          value={this.state.selectedShop}
          onChange={this._handleChange}
        />
      )
    }
  });

  return ShopsSelect
});
