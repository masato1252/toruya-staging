//= require "components/shared/customers_list"
//
"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: this.props.customers
      });
    },

    render: function() {
      return(
        <div id="resNew">
          <UI.Common.CustomersList customers={this.state.customers} />
        </div>
      );
    }
  });

  return CustomersDashboard;
});
