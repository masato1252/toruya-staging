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
            key={customer.value} customer={customer}
            handleCustomerRemove={_this.props.handleCustomerRemove}
            handleCustomerSelect={_this.handleCustomerSelect} />
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

