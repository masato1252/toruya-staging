//= require "components/shared/customers_list"
//
"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: this.props.customers,
        selected_customer_id: ""
      });
    },

    handleCustomerSelect: function(customer_id, event) {
      this.setState({selected_customer_id: customer_id});
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      window.location = this.props.addReservationPath + window.location.search + "," + this.state.selected_customer_id;
    },

    render: function() {
      return(
        <div id="customer" class="contents">
          <div id="resultList" class="sidel">
            <div id="resNew">
              <UI.Common.CustomersList
                customers={this.state.customers}
                handleCustomerSelect={this.handleCustomerSelect}
                selected_customer_id={this.state.selected_customer_id} />
            </div>
          </div>
          <div id="customerInfo" class="contBody">
          </div>

          <div id="mainNav">
            <dl>
              <dd id="NAVaddCustomer">
                <a href="#" className="BTNyellow" onClick={this.handleAddCustomerToReservation}>
                  <span>顧客選択</span>
                </a>
              </dd>
            </dl>
            <dl id="calStatus">
              <dd className="reserved">予約</dd>
              <dd className="checkin">チェックイン</dd>
              <dd className="checkout">チェックアウト</dd>
              <dd className="noshow">未来店</dd>
              <dd className="pending">承認待ち</dd>
            </dl>
          </div>

        </div>
      );
    }
  });

  return CustomersDashboard;
});
