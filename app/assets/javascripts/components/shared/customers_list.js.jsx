//= require "components/shared/customer_option"

"use strict";

UI.define("Common.CustomersList", function() {
  var CustomersList = React.createClass({
    handleCustomerSelect: function(customer_id) {
      if (this.props.handleCustomerSelect) {
        this.props.handleCustomerSelect(customer_id);
      }
    },

    _atEnd: function() {
      // 200 is a align magic number
      return $(this.customerList).scrollTop() + $(this.customerList).innerHeight() + 300 >=
          $(this.customerList)[0].scrollHeight
    },

    _handleScroll: function() {
      if (this._atEnd()) {
        this.props.handleMoreCustomers();
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
          </div>
      );
    }
  });

  return CustomersList;
});
