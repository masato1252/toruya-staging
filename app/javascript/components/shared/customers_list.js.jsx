"use strict";

import React from "react";
import _ from "underscore";
import CommonCustomerOption from "./customer_option.js";

class CommonCustomersList extends React.Component {
  state = {
    listHeight: "60vh"
  };

  componentWillMount() {
    this.handleMoreCustomers = _.debounce(this.props.handleMoreCustomers, 200, true)
  };

  componentDidMount() {
    this.setProperListHeight();
    $(window).resize(() => {
      this.setProperListHeight();
    });
  };

  setProperListHeight = () => {
    this.setState({listHeight: `${$(window).innerHeight() - 300} px`})
  };

  handleCustomerSelect = (customer_id) => {
    if (this.props.handleCustomerSelect) {
      this.props.handleCustomerSelect(customer_id);
    }
  };

  _atEnd = () => {
    // XXX: 1.5 is a magic number, I want to load data easier.
    return $(this.customerList).scrollTop() * 1.5 + $(this.customerList).innerHeight() >= $(this.customerList)[0].scrollHeight
  };

  _handleScroll = () => {
    if (this._atEnd()) {
      this.handleMoreCustomers();
    }
  };

  render() {
    var _this = this;
    var noCustomerMessage = "";

    var customerOptions = this.props.customers.map(function(customer) {
      return (
        <CommonCustomerOption
          {..._this.props}
          customer={customer}
          key={customer.value} />
      );
    });

    if (this.props.noMoreCustomers) {
      if (customerOptions.length === 0) {
        noCustomerMessage = <strong className="no-more-customer">{this.props.noCustomerMessage}</strong>
      }
      else {
        noCustomerMessage = <strong className="no-more-customer">{this.props.noMoreCustomerMessage}</strong>
      }
    }

    return(
      <div
        id="customerList"
        style={{height: this.state.listHeight}}
        ref={(c) => this.customerList = c}
        onScroll={this._handleScroll}>
          {customerOptions}
          {noCustomerMessage}
        </div>
    );
  }
};

export default CommonCustomersList
