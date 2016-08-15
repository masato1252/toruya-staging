//= require "components/reservations/customer_option"
//
"use strict";

UI.define("Reservation.CustomersList", function() {
  var CustomersList = React.createClass({
    render: function() {
      var _this = this;
      var customerOptions = this.props.customers.map(function(customer) {
        return <UI.Reservation.CustomerOption
        key={customer.value} customer={customer}
        handleCustomerRemove={_this.props.handleCustomerRemove}/>;
      });

      return(
        <div class="customers-list">
          {customerOptions}
        </div>
      );
    }
  });

  return CustomersList;
});

