"use strict";

import React from "react";
var createReactClass = require("create-react-class");

UI.define("Common.CustomerOption", function() {
  var CustomerOption = createReactClass({
    _handleClick: function() {
      if (this.props.handleCustomerSelect) {
        this.props.handleCustomerSelect(this.props.customer.value);
      }
    },

    _handleRemove: function() {
      if (this.props.handleCustomerRemove) {
        this.props.handleCustomerRemove(this.props.customer.value);
      }
    },

    render: function() {
      return(
        <dl onClick={this._handleClick} key={this.props.customer.value} className={`customer-option ${this.props.selected_customer_id && this.props.selected_customer_id == this.props.customer.value ? "here" : ""}`}>
          <dd className="customer-symbol">
            <span className={`customer-level-symbol ${this.props.customer.rank.key}`}>
              <i className="fa fa-address-card"></i>
            </span>
          </dd>
          <dt>
            <p>{this.props.customer.label}</p>
            <p className="place">{this.props.customer.address}</p>
          </dt>
          {this.props.handleCustomerRemove ? <dd onClick={this._handleRemove}>
            <span className="BTNyellow customer-remove-symbol glyphicon glyphicon-remove">
              <i className="fa fa-times" aria-hidden="true"></i>
            </span>
          </dd> : null}
        </dl>
      );
    }
  });

  return CustomerOption;
});

export default UI.Common.CustomerOption
