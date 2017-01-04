//= require "components/shared/customer_option"

"use strict";

UI.define("Common.CustomersList", function() {
  var CustomersList = React.createClass({
    componentWillMount: function() {
      this.handleMoreCustomers = _.debounce(this.props.handleMoreCustomers, 200, true)
    },

    handleCustomerSelect: function(customer_id) {
      if (this.props.handleCustomerSelect) {
        this.props.handleCustomerSelect(customer_id);
      }
    },

    _atEnd: function() {
      // XXX: 1.2 is a magic number, I want to load data easier.
      return $(this.customerList).scrollTop() * 1.2 + $(this.customerList).innerHeight() >= $(this.customerList)[0].scrollHeight
    },

    _handleScroll: function() {
      if (this._atEnd()) {
        this.handleMoreCustomers();
      }
    },

    render: function() {
      var _this = this;

      var customerOptions = this.props.customers.map(function(customer) {
        return (
          <UI.Common.CustomerOption
            {..._this.props}
            customer={customer}
            key={customer.value} />
        );
      });

      return(
          <div id="customerList" ref={(c) => this.customerList = c} onScroll={this._handleScroll}>
            {customerOptions}
            {
              this.props.noMoreCustomers ? (
                <strong className="no-more-customer">No More Customer</strong>
              ) : null
            }
          </div>
      );
    }
  });

  return CustomersList;
});
