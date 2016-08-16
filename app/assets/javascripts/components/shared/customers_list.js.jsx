//= require "components/shared/customer_option"

"use strict";

UI.define("Common.CustomersList", function() {
  var CustomersList = React.createClass({
    handleCustomerSelect: function(customer_id) {
      if (this.props.handleCustomerSelect) {
        this.props.handleCustomerSelect(customer_id);
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
        <div id="customers">
          <div id="customerList">
            {customerOptions}
          </div>
        </div>
      );
    }
  });

  return CustomersList;
});

