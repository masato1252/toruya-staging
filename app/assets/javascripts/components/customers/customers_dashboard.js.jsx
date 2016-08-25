//= require "components/shared/customers_list"
//
"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: this.props.customers,
        selected_customer_id: "",
        selectedFilterPatternNumber: ""
      });
    },

    handleCustomerSelect: function(customer_id, event) {
      this.setState({selected_customer_id: customer_id});
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      window.location = this.props.addReservationPath + window.location.search + "," + this.state.selected_customer_id;
    },

    filterCustomers: function(event) {
      event.preventDefault();
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      this.setState({selectedFilterPatternNumber: event.target.value})

      this.currentRequest = jQuery.ajax({
        url: this.props.customersFilterPath,
        data: { pattern_number: event.target.value },
        dataType: "json",
      }).done(
        function(result) {
          _this.setState({customers: result["customers"]});
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    render: function() {
      return(
        <div>
          <div id="customer" className="contents">
            <div id="resultList" className="sidel">
              <ul>
                <li><i className="customer-level-symbol normal" /><span className="wording">一般</span></li>
                <li><i className="customer-level-symbol vip" /><span className="wording">VIP</span></li>
              </ul>
              <div id="resNew">
                <div id="customers">
                  <UI.Common.CustomersList
                    customers={this.state.customers}
                    handleCustomerSelect={this.handleCustomerSelect}
                    selected_customer_id={this.state.selected_customer_id} />
                </div>
              </div>
            </div>
            <div id="customerInfo" className="contBody">
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
                <dd><span className="reservation-state reserved"></span>予約</dd>
                <dd><span className="reservation-state checkin"></span>チェックイン</dd>
                <dd><span className="reservation-state checkout"></span>チェックアウト</dd>
                <dd><span className="reservation-state noshow"></span>未来店</dd>
                <dd><span className="reservation-state pending"></span>承認待ち</dd>
              </dl>
            </div>
          </div>
          <footer>
          <ul>
              {
               ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "A"].map(function(symbol, i) {
                 return (
                   <li key={symbol}
                       onClick={this.filterCustomers}
                       value={i} >
                     <a href="#"
                        value={i}
                        className={this.state.selectedFilterPatternNumber == `${i}` ? "here" : null }>{symbol}</a>
                   </li>
                 )
               }.bind(this))
              }
              <li><input type="text" id="search" placeholder="Name or TEL" /></li>
             </ul>
          </footer>
        </div>
      );
    }
  });

  return CustomersDashboard;
});
