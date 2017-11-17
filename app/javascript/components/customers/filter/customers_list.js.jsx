"use strict";

import React from "react";
import "../../shared/processing_bar.js";

var createReactClass = require("create-react-class");

UI.define("Customers.Filter.CustomersList", function() {
  var CustomersList = createReactClass({
    renderCustomersList: function() {
      return (
        this.props.customers.map(function(customer) {
          return (
            <dl key={customer.id}>
              <dd className="status">
                <span className={`customer-level-symbol ${customer.rank.key}`}>
                  <i className="fa fa-address-card"></i>
                </span>
              </dd>
              <dd className="customer">{customer.label}</dd>
              <dd className="address">{customer.displayAddress}</dd>
              <dd className="group">{customer.groupName}</dd>
            </dl>
          )
        })
      );
    },

    render: function() {
      return (
        <div id="resList" className="contBody">
          <UI.ProcessingBar processing={this.props.processing} processingMessage={this.props.processingMessage} />
          <dl className="tableTTL">
            <dt className="status">&nbsp;</dt>
            <dt className="customer">顧客氏名</dt>
            <dt className="address">住所</dt>
            <dt className="group">顧客台帳</dt>
          </dl>
          <div id="record">
            {this.renderCustomersList()}
          </div>
          <div className="status-list">
            <div><span className="customer-level-symbol regular"><i className="fa fa-address-card"></i></span><span>一般</span></div>
            <div><span className="customer-level-symbol vip"><i className="fa fa-address-card"></i></span><span>VIP</span></div>
          </div>
        </div>
      );
    }
  });

  return CustomersList;
});

export default UI.Customers.Filter.CustomersList;
