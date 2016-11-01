//= require "components/shared/customers_list"
//= require "components/customers/customer_info"
//= require "components/customers/customer_info_view"
//= require "components/customers/customer_info_edit"
//= require "components/customers/search_bar"

"use strict";

UI.define("Customers.Dashboard", function() {
  var CustomersDashboard = React.createClass({
    getInitialState: function() {
      this.currentCustomersType = "recent" // recent, filter, search
      this.lastQuery = ""

      return ({
        customers: this.props.customers,
        selected_customer_id: "",
        selectedFilterPatternNumber: "",
        customer: this.props.customer
      });
    },

    fetchCustomerDetails: function() {
      var _this = this;
      if (this.state.customer) {
        $.ajax({
          type: "GET",
          url: this.props.customerDetailPath,
          data: { id: this.state.customer.id },
          dataType: "JSON"
        }).success(function(result) {
          _this.setState({customer: result["customer"]});
        });
      }
    },

    handleCustomerSelect: function(customer_id, event) {
      if (this.state.selected_customer_id == customer_id) {
        this.setState({selected_customer_id: "", customer: {}});
      }
      else {
        var selected_customer = _.find(this.state.customers, function(customer){ return customer.id == customer_id; })
        this.setState({selected_customer_id: customer_id, customer: selected_customer}, this.fetchCustomerDetails);
      }
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      window.location = this.props.addReservationPath + window.location.search + "," + this.state.selected_customer_id;
    },

    isCustomerdataValid: function() {
      return this.state.customer.firstName || this.state.customer.lastName || this.state.customer.jpFirstName || this.state.customer.jpLastName
    },

    handleCreateCustomer: function(event) {
      event.preventDefault();

      var _this = this;

      if (this.isCustomerdataValid()) {
        var valuesToSubmit = $(this.customerForm).serialize();

        $.ajax({
          type: "POST",
          url: this.props.saveCustomerPath, //sumbits it to the given url of the form
          data: valuesToSubmit,
          dataType: "JSON"
        }).success(function(result){
          _this.state.customers.unshift(result["customer"])
          _this.setState({customers: _this.state.customers, customer: {}, selected_customer_id: ""});
        });
      }
    },

    handleDeleteCustomer: function(event) {
      event.preventDefault();

      var _this = this;

      this.setState({customers: _.reject(this.state.customers, function(customer) {
        return customer.id == _this.state.selected_customer_id;
      }), customer: {}, selected_customer_id: ""})

      jQuery.ajax({
        type: "POST",
        url: this.props.deleteCustomerPath,
        data: { _method: "delete", id: this.state.selected_customer_id },
        dataType: "json",
      })
    },

    handleMoreCustomers: function(event) {
      switch (this.currentCustomersType) {
        case "recent":
          this.recentCutomers()
          break;
        case "filter":
          this.filterCustomers()
          break;
        case "search":
          this.SearchCustomers()
          break;
      }
    },

    recentCutomers: function() {
      var originalCustomers = this.state.customers;
      var data;

      if (this.currentCustomersType != "recent") {
        originalCustomers = [];
        this.currentCustomersType = "recent";
      }
      data =  { updated_at: this.state.customers[this.state.customers.length-1].updatedAt }

      this.customersRequest(this.props.customersRecentPath, data, originalCustomers);
    },

    filterCustomers: function(event) {
      var data;
      var originalCustomers = this.state.customers;

      if (event) {
        event.preventDefault();
        if (this.currentCustomersType != "filter" || event.target.value != this.lastQuery) {
          originalCustomers = [];
          this.currentCustomersType = "filter";
        }

        this.lastQuery = event.target.value
        data =  { pattern_number: this.lastQuery }
      }
      else {
        data =  { pattern_number: this.lastQuery,
                  last_customer_id: this.state.customers[this.state.customers.length-1].id }
      }

      this.setState({selectedFilterPatternNumber: this.lastQuery})
      this.customersRequest(this.props.customersFilterPath, data, originalCustomers);
    },

    SearchCustomers: function(event) {
      if ((event && event.key === 'Enter') || !event) {
        var data, originalCustomers;
        var originalCustomers = this.state.customers;

        if (event) {
          event.preventDefault();
          if (this.currentCustomersType != "search" || event.target.value != this.lastQuery) {
            originalCustomers = [];
            this.currentCustomersType = "search";
          }

          this.lastQuery = event.target.value
          data = { keyword: this.lastQuery };
        }
        else {
          data =  { keyword: this.lastQuery,
                    last_customer_id: this.state.customers[this.state.customers.length-1].id }
        }

        this.customersRequest(this.props.customersSearchPath, data, originalCustomers);
      }
    },

    customersRequest: function(path, data, originalCustomers) {
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      this.currentRequest = jQuery.ajax({
        url: path,
        data: data,
        dataType: "json",
      }).done(function(result) {
        _this.setState({customers: originalCustomers.concat(result["customers"])});
      }).fail(function(errors){
      }).always(function() {
        _this.setState({Loading: false});
      });
    },

    handleCustomerDataChange: function(event) {
      event.preventDefault();
      var newCustomer = this.state.customer;

      newCustomer[event.target.dataset.name] = event.target.value;

      this.setState({customer: newCustomer});
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
                    handleMoreCustomers={this.handleMoreCustomers}
                    selected_customer_id={this.state.selected_customer_id} />
                </div>
              </div>
            </div>

            <UI.Customers.CustomerInfoView
              customer={this.state.customer}
              handleCustomerDataChange={this.handleCustomerDataChange}
              fetchCustomerDetails={this.fetchCustomerDetails} />

            <div id="mainNav">
              { this.props.fromReservation ? (
                <dl>
                  <dd id="NAVaddCustomer">
                    <a href="#" className="BTNyellow" onClick={this.handleAddCustomerToReservation}>
                      <span>顧客選択</span>
                    </a>
                  </dd>
                  </dl>) : (
                  <div>
                    <dl>
                      <dd id="NAVnewResv">
                        <a href={this.props.addReservationPath} className="BTNtarco"><span>新規予約</span></a>
                      </dd>
                      <dd id="NAVsave">
                        <form id="new_customer_form"
                          ref={(c) => {this.customerForm = c}}
                          acceptCharset="UTF-8" action={this.props.saveCustomerPath} method="post">
                          <input name="customer[id]" type="hidden" value={this.state.customer.id} />
                          <input name="customer[first_name]" type="hidden" value={this.state.customer.firstName} />
                          <input name="customer[last_name]" type="hidden" value={this.state.customer.lastName} />
                          <input name="customer[phonetic_last_name]" type="hidden" value={this.state.customer.jpLastName} />
                          <input name="customer[phonetic_first_name]" type="hidden" value={this.state.customer.jpFirstName} />
                          <input name="customer[state]" type="hidden" value={this.state.customer.state} />
                          <input name="customer[phone_type]" type="hidden" value={this.state.customer.phoneType} />
                          <input name="customer[phone_number]" type="hidden" value={this.state.customer.phoneNumber} />
                          <input name="customer[birthday]" type="hidden" value={this.state.customer.birthday} />
                          <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />
                          <a href="#"
                             className={`BTNyellow ${this.isCustomerdataValid() ? null : "disabled"}`} onClick={this.handleCreateCustomer}><span>上書き保存</span>
                          </a>
                        </form>
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
                  )
              }
            </div>
          </div>
          <footer>
            <UI.Customers.SearchBar
              filterCustomers={this.filterCustomers}
              selectedFilterPatternNumber={this.state.selectedFilterPatternNumber}
              SearchCustomers={this.SearchCustomers} />
          </footer>
        </div>
      );
    }
  });

  return CustomersDashboard;
});
