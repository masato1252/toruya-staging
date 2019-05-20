"use strict";

import React from "react";
import ProcessingBar from "../../../shared/processing_bar.js";

class FilterCustomersList extends React.Component {
  onCustomerClick = (customer) => {
    if (window.confirm(this.props.customerInfoConfirmMessage + customer.label)) {
       window.location = `${this.props.customerPath}?customer_id=${customer.id}`;
    }
  }

  renderCustomersList = () => {
    return (
      this.props.customers.map(function(customer) {
        return (
          <dl key={customer.id} onClick={this.onCustomerClick.bind(this, customer)}>
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
      }.bind(this))
    );
  };

  render() {
    return (
      <div id="resList" className="contBody">
        <ProcessingBar processing={this.props.processing} processingMessage={this.props.processingMessage} />
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
};

export default FilterCustomersList;
