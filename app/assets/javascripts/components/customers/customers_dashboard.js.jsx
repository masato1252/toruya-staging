//= require "components/shared/customers_list"
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
        selected_customer_id: (this.props.customer ? this.props.customer.id : ""),
        selectedFilterPatternNumber: "",
        customer: this.props.customer,
        edit_mode: !this.props.reservationMode,
        reservation_mode: this.props.reservationMode,
        processing: false,
        moreCustomerProcessing: false,
        no_more_customers: false
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
          _this.forceStopProcessing()
      });
      }
    },

    newCustomerMode: function() {
      this.setState({selected_customer_id: "", customer: {}, processing: false, edit_mode: true, reservation_mode: false});
    },

    handleCustomerSelect: function(customer_id, event) {
      // if (this.state.processing) { return; }
      if (this.state.selected_customer_id == customer_id) {
        this.newCustomerMode()
      }
      else {
        var selected_customer = _.find(this.state.customers, function(customer){ return customer.id == customer_id; })
        this.setState(
          {selected_customer_id: customer_id, customer: selected_customer,
           processing: true, edit_mode: false, reservation_mode: true}, function() {
            if (this.CustomerReservationsView) {
              this.CustomerReservationsView.fetchReservations()
            }

            this.fetchCustomerDetails();
          }.bind(this)
          );
      }
    },

    handleAddCustomerToReservation: function(event) {
      event.preventDefault();
      if (!this.state.selected_customer_id) { return; }
      window.location = this.props.addReservationPath + window.location.search + "," + (this.state.selected_customer_id || "");
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
      this.setState({moreCustomerProcessing: true}, function() {
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
      }.bind(this));
    },

    recentCutomers: function() {
      var originalCustomers = this.state.customers;
      var data;
      var stateChanges = {}

      if (this.currentCustomersType != "recent") {
        $("body").scrollTop(0)
        $("#customerList").scrollTop(0)
        originalCustomers = [];
        this.currentCustomersType = "recent";
        stateChanges["no_more_customers"] = false
        stateChanges["processing"] = true
      }

      data =  { updated_at: this.state.customers[this.state.customers.length-1].updatedAt }

      this.setState(stateChanges, function() {
        this.customersRequest(this.props.customersRecentPath, data, originalCustomers);
      }.bind(this))
    },

    filterCustomers: function(event) {
      var data;
      var stateChanges = {}
      var originalCustomers = this.state.customers;

      if (event) {
        event.preventDefault();
        $("body").scrollTop(0)
        $("#customerList").scrollTop(0)
        if (this.currentCustomersType != "filter" || event.target.value != this.lastQuery) {
          originalCustomers = [];
          this.currentCustomersType = "filter";
          stateChanges["no_more_customers"] = false
          stateChanges["processing"] = true
        }

        this.lastQuery = event.target.value
        data =  { pattern_number: this.lastQuery }
      }
      else {
        data =  { pattern_number: this.lastQuery,
                  last_customer_id: _.max(this.state.customers.map(function(c) { return c.id })) }
      }

      stateChanges["selectedFilterPatternNumber"] = this.lastQuery

      this.setState(stateChanges, function() {
        this.customersRequest(this.props.customersFilterPath, data, originalCustomers);
      }.bind(this))
    },

    SearchCustomers: function(event) {
      if ((event && event.key === 'Enter') || !event) {
        // Hide the keyword
        document.activeElement.blur();
        $(event.target).blur();

        var data, originalCustomers;
        var originalCustomers = this.state.customers;
        var stateChanges = {}

        if (event) {
          event.preventDefault();
          $("body").scrollTop(0);
          $("#customerList").scrollTop(0);

          if (this.currentCustomersType != "search" || event.target.value != this.lastQuery) {
            originalCustomers = [];
            this.currentCustomersType = "search";
            stateChanges["no_more_customers"] = false
            stateChanges["selectedFilterPatternNumber"] = ""
            stateChanges["processing"] = true
          }

          this.lastQuery = event.target.value
          data = { keyword: this.lastQuery };
          $(event.target).val("");
        }
        else {
          data =  { keyword: this.lastQuery,
                    last_customer_id: this.state.customers[this.state.customers.length-1].id }
        }

        this.setState(stateChanges, function() {
          this.customersRequest(this.props.customersSearchPath, data, originalCustomers);
        }.bind(this))
      }
    },

    customersRequest: function(path, data, originalCustomers) {
      var _this = this;

      if (this.currentRequest != null) {
        this.currentRequest.abort();
      }

      if (this.state.no_more_customers) {
        this.setState({moreCustomerProcessing: false})
        return;
      }

      this.currentRequest = jQuery.ajax({
        url: path,
        data: data,
        dataType: "json",
      }).done(function(result) {
        if (result["customers"].length == 0) {
          _this.setState({no_more_customers: true, moreCustomerProcessing: false, customers: originalCustomers.concat(result["customers"])})
        }
        else {
          var noMoreCustomers = false;
          if (result["customers"].length < _this.props.perPage) {
            noMoreCustomers = true;
          }

          _this.setState({customers: originalCustomers.concat(result["customers"]), no_more_customers: noMoreCustomers});
        }
      }).fail(function(errors){
      }).always(function() {
        _this.setState({moreCustomerProcessing: false, processing: false});
      });
    },

    _handleCreatedCustomer: function(customer) {
      this.state.customers = _.reject(this.state.customers, function(c) {
        return customer.id == c.id;
      })

      this.state.customers.unshift(customer)
      this.setState({customers: this.state.customers, customer: customer, selected_customer_id: customer.id});
    },

    handleCustomerCreate: function(event) {
      if (this.state.processing) { return ;}
      this.customer_info_edit.handleCreateCustomer(event);
    },

    _isCustomerDataValid: function() {
      return (this.state.customer.lastName && this.state.customer.firstName) ||
        (this.state.customer.phoneticLastName && this.state.customer.phoneticFirstName)
    },

    handleNewReservation: function(event) {
      event.preventDefault();
      window.location = `${this.props.addReservationPath}?customer_ids=${(this.state.selected_customer_id || "")}`;
    },

    removeOption: function(optionType, index) {
      var newCustomer = this.state.customer;
      newCustomer[optionType].splice(index, 1)

      this.setState({customer: newCustomer});
    },

    addOption: function(optionType, index) {
      var newCustomer = this.state.customer;
      var defaultValue = optionType == "emails" ? { address: ""} : "";
      if (!newCustomer[optionType]) {
        newCustomer[optionType] = [];
      }

      newCustomer[optionType].push({ type: "home", value: defaultValue });

      this.setState({customer: newCustomer});
    },

    handleCustomerDataChange: function(event) {
      event.preventDefault();
      var newCustomer = this.state.customer;
      var keyName = event.target.dataset.name;

      if (keyName == "birthday-year" || keyName == "birthday-month" || keyName == "birthday-day") {
        var key = event.target.dataset.name.split("-");
        if (newCustomer["birthday"] == "") {
          newCustomer["birthday"] = {};
        }

        if (!newCustomer["birthday"]) {
          newCustomer["birthday"] = {}
        }

        newCustomer["birthday"][key[1]] = event.target.value;
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

          // Auto focus to postcode2 when typing 3 letters in postcode1
          if (key[1] == "postcode1" && event.target.value.length == 3) { $("#zipcode4").focus(); }
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
      this.setState({ processing: true }, function() {
        if (callback) { callback(); }
      })
    },

    forceStopProcessing: function() {
      this.setState({ processing: false });
    },

    renderCustomerView: function() {
      var _this = this;

      if (this.state.reservation_mode) {
        return (
          <UI.Customers.CustomerReservationsView
            ref={(c) => this.CustomerReservationsView = c }
            customer={this.state.customer}
            switchReservationMode={this.switchReservationMode}
            customerReservationsPath={this.props.customerReservationsPath}
            switchProcessing={this.switchProcessing}
            forceStopProcessing={this.forceStopProcessing}
            stateCustomerReservationsPath={this.props.stateCustomerReservationsPath}
            editCustomerReservationsPath={this.props.editCustomerReservationsPath}
            deleteConfirmationMessage={this.props.deleteConfirmationMessage}
            shop={this.props.shop}
            checkInBtn={this.props.checkInBtn}
            checkOutBtn={this.props.checkOutBtn}
            acceptBtn={this.props.acceptBtn}
            pendBtn={this.props.pendBtn}
            editBtn={this.props.editBtn}
            cancelBtn={this.props.cancelBtn}
            />
        )
      }
      else if (this.state.edit_mode) {
        return (
          <UI.Customers.CustomerInfoEdit
            ref={function(c) { this.customer_info_edit = c }.bind(this)}
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
            forceStopProcessing={this.forceStopProcessing}
            switchReservationMode={this.switchReservationMode}
            saveCustomerPath={this.props.saveCustomerPath}
            fetchCustomerDetails={this.fetchCustomerDetails}
            delimiter={this.props.delimiter}
            backWithoutSaveBtn={this.props.backWithoutSaveBtn}
            selectRegionLabel={this.props.selectRegionLabel}
            customerIdPlaceholder={this.props.customerIdPlaceholder}
            selectYearLabel={this.props.selectYearLabel}
            selectMonthLabel={this.props.selectMonthLabel}
            selectDayLabel={this.props.selectDayLabel}
            homeLabel={this.props.homeLabel}
            workLabel={this.props.workLabel}
            mobileLabel={this.props.mobileLabel}
            cityPlaceholder={this.props.cityPlaceholder}
            address1Placeholder={this.props.address1Placeholder}
            address2Placeholder={this.props.address2Placeholder}
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
          <UI.ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
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
                    selected_customer_id={this.state.selected_customer_id}
                    noMoreCustomers={this.state.no_more_customers}
                    noMoreCustomerMessage={this.props.noMoreCustomerMessage}
                    noCustomerMessage={this.props.noCustomerMessage}
                    displayNewCustomerBtn={this.state.selected_customer_id}
                    newCustomerMode={this.newCustomerMode}
                    processing={this.state.processing}
                    />
                  <UI.ProcessingBar processing={this.state.moreCustomerProcessing} processingMessage={this.props.processingMessage} />
                  {
                    this.state.selected_customer_id ? (
                      <button
                        id="new-customer-btn"
                        className="btn btn-light-green"
                        onClick={this.newCustomerMode}
                        disabled={this.state.processing} >
                        新規データ作成
                      </button>
                    ) : null
                  }
                </div>
              </div>
            </div>

            {this.renderCustomerView()}

            <div id="mainNav">
              { this.props.fromReservation ? (
                <dl>
                  <dd id="NAVaddCustomer">
                    <a href="#" className={`BTNyellow ${!this.state.selected_customer_id ? "disabled" : null}`} onClick={this.handleAddCustomerToReservation}>
                      <i className="fa fa-calendar-plus-o fa-2x"></i>
                      <span>顧客選択</span>
                    </a>
                  </dd>
                  </dl>) : (
                  <div>
                    <dl>
                      {
                        this.state.edit_mode ? (
                          <a href="#"
                            onClick={this.handleCustomerCreate}
                            className={`BTNyellow ${!this._isCustomerDataValid() || this.state.processing ? "disabled" : null}`}
                            >
                            <dd id="NAVnewResv">
                              <i className="fa fa-folder-o fa-2x"></i>
                              <span>{this.props.saveBtn}</span>
                            </dd>
                          </a>
                        ) : (
                          <a
                            href="#"
                            onClick={this.handleNewReservation}
                            className="BTNtarco"
                            >
                            <dd id="NAVnewResv">
                              <i className="fa fa-calendar-plus-o fa-2x"></i>
                              <span>新規予約</span>
                            </dd>
                          </a>
                        )
                      }
                      <dd id="NAVsave">
                        <form id="new_customer_form"
                          ref={(c) => {this.customerForm = c}}
                          acceptCharset="UTF-8" action={this.props.saveCustomerPath} method="post">
                          <input name="customer[id]" type="hidden" defaultValue={this.state.customer.id || ""} />
                          <input name="customer[first_name]" type="hidden" defaultValue={this.state.customer.firstName || ""} />
                          <input name="customer[last_name]" type="hidden" defaultValue={this.state.customer.lastName || ""} />
                          <input name="customer[phonetic_last_name]" type="hidden" defaultValue={this.state.customer.jpLastName || ""} />
                          <input name="customer[phonetic_first_name]" type="hidden" defaultValue={this.state.customer.jpFirstName || ""} />
                          <input name="customer[state]" type="hidden" defaultValue={this.state.customer.state || ""} />
                          <input name="customer[phone_type]" type="hidden" defaultValue={this.state.customer.phoneType || ""} />
                          <input name="customer[phone_number]" type="hidden" defaultValue={this.state.customer.phoneNumber || ""} />
                          <input name="customer[birthday]" type="hidden" defaultValue={this.state.customer.birthday || ""} />
                          <input name="authenticity_token" type="hidden" defaultValue={this.props.formAuthenticityToken} />
                        </form>
                      </dd>
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
