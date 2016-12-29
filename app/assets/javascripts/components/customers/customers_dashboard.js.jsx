//= require "components/shared/customers_list"
//= require "components/customers/customer_info"
//= require "components/customers/customer_info_view"
//= require "components/customers/customer_info_edit"
//= require "components/customers/customer_reservations_view"
//= require "components/customers/search_bar"
//= require "components/shared/processing_bar"

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
        customer: this.props.customer,
        edit_mode: true,
        reservation_mode: this.props.reservationMode,
        processing: false
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
        }).always(function() {
        _this.setState({processing: false});
      });
      }
    },

    handleCustomerSelect: function(customer_id, event) {
      if (this.state.processing) { return; }
      if (this.state.selected_customer_id == customer_id) {
        this.setState({selected_customer_id: "", customer: {}});
      }
      else {
        var selected_customer = _.find(this.state.customers, function(customer){ return customer.id == customer_id; })
        this.setState(
          {selected_customer_id: customer_id, customer: selected_customer, processing: true}, function() {
            this.fetchCustomerDetails();
            if (this.CustomerReservationsView) {
              this.CustomerReservationsView.fetchReservations()
            }
          }.bind(this)
          );
      }
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      window.location = this.props.addReservationPath + window.location.search + "," + this.state.selected_customer_id;
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
      this.setState({processing: true});
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

      this.setState({processing: true})
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

      this.setState({selectedFilterPatternNumber: this.lastQuery, processing: true})
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

        this.setState({processing: true})
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
        _this.setState({processing: false});
      });
    },

    _handleCreatedCustomer: function(customer) {
      if (!this.state.customers.find(function(c) { return(c.id == customer.id); })) {
        this.state.customers.unshift(customer)
      }
      this.setState({customers: this.state.customers, customer: customer, selected_customer_id: customer.id});
    },

    removeOption: function(optionType, index) {
      var newCustomer = this.state.customer;
      newCustomer[optionType].splice(index, 1)

      this.setState({customer: newCustomer});
    },

    addOption: function(optionType, index) {
      var newCustomer = this.state.customer;
      var defaultValue = optionType == "emails" ? { address: ""} : "";

      newCustomer[optionType].push({ type: "home", value: defaultValue });

      this.setState({customer: newCustomer});
    },

    handleCustomerDataChange: function(event) {
      event.preventDefault();
      var newCustomer = this.state.customer;
      var keyName = event.target.dataset.name;

      if (keyName == "birthday-year" || keyName == "birthday-month" || keyName == "birthday-day") {
        var key = event.target.dataset.name.split("-");
        newCustomer[key[0]][key[1]] = event.target.value;
      }
      else {
        newCustomer[keyName] = event.target.value;
      }

      this.setState({customer: newCustomer});
    },

    handleCustomerGoogleDataChange: function(event) {
      event.preventDefault();
      var newCustomer = this.state.customer;

      switch (event.target.dataset.name) {
        case "primaryPhone":
          var value = event.target.value.split(this.props.delimiter);
          newCustomer[event.target.dataset.name] = { type: value[0], value: value[1] };
          break;
        case "primaryEmail":
          var value = event.target.value.split(this.props.delimiter);
          newCustomer[event.target.dataset.name] = { type: value[0], value: { address: value[1] }};
          break;
        case "primaryAddress-postcode1":
        case "primaryAddress-postcode2":
        case "primaryAddress-region":
        case "primaryAddress-city":
        case "primaryAddress-street1":
        case "primaryAddress-street2":
          var key = event.target.dataset.name.split("-");
          newCustomer[key[0]] = newCustomer[key[0]] || {};
          newCustomer[key[0]]["value"] = newCustomer[key[0]]["value"] || {};
          newCustomer[key[0]]["value"][key[1]] = event.target.value;
          break;
        case "phoneNumbers-type":
        case "phoneNumbers-value":
        case "emails-type":
          var key = event.target.dataset.valueName.split("-");
          newCustomer[key[0]][parseInt(key[2])][key[1]] = event.target.value;
          break;
        case "emails-value":
          var key = event.target.dataset.valueName.split("-");
          newCustomer.emails[parseInt(key[2])]["value"]["address"] = event.target.value;
          break;
      }

      this.setState({customer: newCustomer});
    },

    switchEditMode: function() {
      if (this.state.processing) { return; }
      this.setState({ edit_mode: !this.state.edit_mode });
    },

    switchReservationMode: function(event) {
      event.preventDefault();
      if (this.state.processing) { return; }
      if (this.state.customer.id) {
        this.setState({ reservation_mode: !this.state.reservation_mode });
      }
    },

    switchProcessing: function(callback) {
      this.setState({ processing: !this.state.processing }, function() {
        if (callback) callback()
      });
    },

    renderCustomerView: function() {
      if (this.state.reservation_mode) {
        return (
          <UI.Customers.CustomerReservationsView
            ref={(c) => this.CustomerReservationsView = c }
            customer={this.state.customer}
            switchReservationMode={this.switchReservationMode}
            customerReservationsPath={this.props.customerReservationsPath}
            switchProcessing={this.switchProcessing}
            stateCustomerReservationsPath={this.props.stateCustomerReservationsPath}
            editCustomerReservationsPath={this.props.editCustomerReservationsPath}
            shop={this.props.shop}
            />
        )
      }
      else if (this.state.edit_mode) {
        return (
          <UI.Customers.CustomerInfoEdit
            customer={this.state.customer}
            contactGroups={this.props.contactGroups}
            ranks={this.props.ranks}
            regions={this.props.regions}
            yearOptions={this.props.yearOptions}
            monthOptions={this.props.monthOptions}
            dayOptions={this.props.dayOptions}
            removeOption={this.removeOption}
            addOption={this.addOption}
            formAuthenticityToken={this.props.formAuthenticityToken}
            handleCustomerDataChange={this.handleCustomerDataChange}
            handleCustomerGoogleDataChange={this.handleCustomerGoogleDataChange}
            handleCreatedCustomer={this._handleCreatedCustomer}
            switchEditMode={this.switchEditMode}
            switchProcessing={this.switchProcessing}
            switchReservationMode={this.switchReservationMode}
            saveCustomerPath={this.props.saveCustomerPath}
            fetchCustomerDetails={this.fetchCustomerDetails}
            delimiter={this.props.delimiter}
            addressLabel={this.props.addressLabel}
            phoneLabel={this.props.phoneLabel}
            emailLabel={this.props.emailLabel}
            birthdayLabel={this.props.birthdayLabel}
            memoLabel={this.props.memoLabel}
            saveBtn={this.props.saveBtn}
            />
        )
      }
      else {
        return (
          <UI.Customers.CustomerInfoView
            customer={this.state.customer}
            switchEditMode={this.switchEditMode}
            switchReservationMode={this.switchReservationMode}
            addressLabel={this.props.addressLabel}
            phoneLabel={this.props.phoneLabel}
            emailLabel={this.props.emailLabel}
            birthdayLabel={this.props.birthdayLabel}
            memoLabel={this.props.memoLabel}
            editBtn={this.props.editBtn}
            />
        );
      }

    },

    render: function() {
      return(
        <div>
          <UI.ProcessingBar processing={this.state.processing} />
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

            {this.renderCustomerView()}

            <div id="mainNav">
              { this.props.fromReservation ? (
                <dl>
                  <dd id="NAVaddCustomer">
                    <a href="#" className="BTNyellow" onClick={this.handleAddCustomerToReservation}>
                      <i className="fa fa-calendar-plus-o fa-2x"></i>
                      <span>顧客選択</span>
                    </a>
                  </dd>
                  </dl>) : (
                  <div>
                    <dl>
                      <dd id="NAVnewResv">
                        <a href={this.props.addReservationPath} className="BTNtarco">
                          <i className="fa fa-calendar-plus-o fa-2x"></i>
                          <span>新規予約</span>
                        </a>
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
