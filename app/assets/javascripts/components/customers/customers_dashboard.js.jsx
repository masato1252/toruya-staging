//= require "components/shared/customers_list"
//
"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    render: function() {

      return(
        <UI.Common.CustomersList customers={this.state.customers} />
      );
    }
  });

  return CustomersDashboard;
});
