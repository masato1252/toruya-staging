"use strict";

UI.define("Reservation.CustomerOption", function() {
  var CustomerOption = React.createClass({
    render: function() {
      var customer_id = this.props.customer.value
      return(
        <div class="customer-option">
          {this.props.customer["label"]}-{this.props.customer["value"]}
          <div onClick={this.props.handleCustomerRemove.bind(null, customer_id)}>Remove This Customer</div>
        </div>
      );
    }
  });

  return CustomerOption;
});

