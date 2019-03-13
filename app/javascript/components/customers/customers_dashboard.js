"use strict";

import React from "react";
import _ from "underscore";
import "whatwg-fetch";
import CommonCustomersList from "../shared/customers_list.js";
import ProcessingBar from "../shared/processing_bar.js";
import CustomerInfoView from "./customer_info_view.js";
import CustomerInfoEdit from "./customer_info_edit.js";
import CustomerReservationsView from "./customer_reservations_view.js";
import CustomersSearchBar from "./search_bar.js";
import Select from "../shared/select.js";
import MessageBar from "../shared/message_bar.js";

class CustomersDashboard extends React.Component {
  constructor(props) {
    super(props);

    this.currentCustomersType = "recent" // recent, filter, search
    this.lastQuery = ""
    this.currentPage = 1;

    this.state = {
      customers: this.props.customers,
      selected_customer_id: (this.props.customer ? this.props.customer.id : ""),
      selectedFilterPatternNumber: "",
      customer: this.props.customer,
      updated_customer: this.props.customer,
      edit_mode: !this.props.reservationMode,
      reservation_mode: this.props.reservationMode,
      processing: false,
      moreCustomerProcessing: false,
      no_more_customers: false,
      printing_page_size: "",
      didSearch: false
    }
  };

  componentDidMount() {
    this.fetchCustomerDetails()
  };

  fetchCustomerDetails = () => {
    var _this = this;
    if (this.state.selected_customer_id) {
      $.ajax({
        type: "GET",
        url: this.props.customerDetailPath,
        data: { id: this.state.selected_customer_id },
        dataType: "JSON"
      }).success(function(result) {
        _this.setState({customer: result["customer"], updated_customer: result["customer"]});
      }).always(function() {
        _this.forceStopProcessing()
    });
    }
  };

  newCustomerMode = (mode="") => {
    let didSearch = false;

    if (mode !== "manual" && (this.currentCustomersType === "search" || this.currentCustomersType === "filter")) {
      didSearch = true;
    }

    this.setState({selected_customer_id: "", customer: {}, processing: false, edit_mode: true, reservation_mode: false, didSearch: didSearch});

    if (mode === "manual") {
      // From select user get into new customer mode
      this.recentCutomers()
    }
  };

  handleCustomerSelect = (customer_id, event) => {
    // if (this.state.processing) { return; }
    if (this.state.selected_customer_id == customer_id) {
      this.newCustomerMode()
    }
    else {
      var selected_customer = _.find(this.state.customers, function(customer){ return customer.id == customer_id; })
      this.setState(
        {selected_customer_id: customer_id, customer: selected_customer,
         processing: true, edit_mode: false, reservation_mode: true,
         didSearch: true}, function() {
          if (this.CustomerReservationsView) {
            this.CustomerReservationsView.fetchReservations()
          }

          this.fetchCustomerDetails();
        }.bind(this)
        );
    }
  };

  handleAddCustomerToReservation = (event) => {
    event.preventDefault();
    if (!this.state.selected_customer_id) { return; }
    window.location = this.props.addReservationPath + window.location.search + "," + (this.state.selected_customer_id || "");
  };

  handleWithoutCustomerToReservation = () => {
    event.preventDefault();
    window.location = this.props.addReservationPath + window.location.search;
  };

  handleDeleteCustomer = (event) => {
    event.preventDefault();
    var _this = this;

    this.switchProcessing(function(){
      $.ajax({
        type: "POST",
        url: _this.props.deleteCustomerPath,
        data: { _method: "delete", id: _this.state.selected_customer_id },
        dataType: "JSON"
      }).success(function(result) {
        _this.setState({
          customers: _.reject(_this.state.customers, function(customer) {
            return customer.id == _this.state.selected_customer_id;
          })
        })
        _this.newCustomerMode();
      }).error(function(jqXhr) {
        alert(jqXhr.responseJSON.error);
      }).always(function() {
        _this.forceStopProcessing();
      });
    })
  };

  handleMoreCustomers = (event) => {
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
  };

  recentCutomers = () => {
    var originalCustomers = this.state.customers;
    var data;
    var stateChanges = { selectedFilterPatternNumber: "" };

    if (this.currentCustomersType != "recent") {
      $("body").scrollTop(0)
      $("#customerList").scrollTop(0)
      originalCustomers = [];
      this.currentCustomersType = "recent";
      stateChanges["no_more_customers"] = false
      stateChanges["processing"] = true
      this.currentPage = 0;
    }

    data = { page: this.currentPage += 1 }

    this.setState(stateChanges, function() {
      this.customersRequest(this.props.customersRecentPath, data, originalCustomers);
    }.bind(this))
  };

  filterCustomers = (event) => {
    var data;
    var stateChanges = {}
    var originalCustomers = this.state.customers;
    var stateChanges = { didSearch: true };

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

      this.currentPage = 0;
      this.lastQuery = event.target.dataset.value
    }

    data = { pattern_number: this.lastQuery, page: this.currentPage += 1 }
    stateChanges["selectedFilterPatternNumber"] = this.lastQuery

    this.setState(stateChanges, function() {
      this.newCustomerMode();
      this.customersRequest(this.props.customersFilterPath, data, originalCustomers);
    }.bind(this))
  };

  SearchCustomers = (event) => {
    if ((event && event.key === 'Enter') || !event) {
      // Hide the keyword
      document.activeElement.blur();

      var data, originalCustomers;
      var originalCustomers = this.state.customers;
      var stateChanges = { didSearch: true };

      if (event) {
        $(event.target).blur();
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

        this.currentPage = 0
        this.lastQuery = event.target.value
        $(event.target).val("");
      }

      data = { keyword: this.lastQuery, page: this.currentPage += 1 }
      this.setState(stateChanges, function() {
        this.newCustomerMode();
        this.customersRequest(this.props.customersSearchPath, data, originalCustomers);
      }.bind(this))
    }
  };

  customersRequest = (path, data, originalCustomers) => {
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
  };

  _handleCreatedCustomer = (customer) => {
    this.state.customers = _.reject(this.state.customers, function(c) {
      return customer.id == c.id;
    })

    this.state.customers.unshift(customer)
    this.setState({customers: this.state.customers, customer: customer, updated_customer: customer, selected_customer_id: customer.id});
  };

  handleCustomerCreate = (event) => {
    if (this.state.processing || !this._isCustomerDataValid()) { return ;}
    this.customer_info_edit.handleCreateCustomer(event);
  };

  _isCustomerDataValid = () => {
    return this.state.customer.contactGroupId && ((this.state.customer.lastName && this.state.customer.firstName) ||
      (this.state.customer.phoneticLastName && this.state.customer.phoneticFirstName))
  };

  handleNewReservation = (event) => {
    event.preventDefault();
    if (!this.props.shop) {
      $("#reservationCreationNoShopModal").modal("show");
      return;
    }

    window.location = `${this.props.addReservationPath}?customer_ids=${(this.state.selected_customer_id || "")}`;
  };

  removeOption = (optionType, index) => {
    let newCustomer = jQuery.extend(true, {}, this.state.customer);
    let originalValue = this.state.customer[`${optionType}Original`]

    newCustomer[optionType].splice(index, 1)

    if (!this.props.customerEditPermission && !_.isEqual(newCustomer[optionType].slice(0, originalValue.length), originalValue)) { return; }

    this.setState({customer: newCustomer});
  };

  addOption = (optionType, index) => {
    let newCustomer = jQuery.extend(true, {}, this.state.customer);
    var defaultValue = optionType == "emails" ? { address: ""} : "";
    if (!newCustomer[optionType]) {
      newCustomer[optionType] = [];
    }

    newCustomer[optionType].push({ type: "home", value: defaultValue });

    this.setState({customer: newCustomer});
  };

  handleCustomerDataChange = (event) => {
    event.preventDefault();
    let newCustomer = jQuery.extend(true, {}, this.state.customer);
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
  };

  handleCustomerGoogleDataChange = (event) => {
    event.preventDefault();
    var newCustomer = jQuery.extend(true, {}, this.state.customer);
    let originalValue;

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
        if (!this.addressEditPermission()) { return; }

        newCustomer[key[0]] = newCustomer[key[0]] || {};
        newCustomer[key[0]]["value"] = newCustomer[key[0]]["value"] || {};
        newCustomer[key[0]]["value"][key[1]] = event.target.value;

        // Auto focus to postcode2 when typing 3 letters in postcode1
        if (key[1] == "postcode1" && event.target.value.length == 3) { $("#zipcode4").focus(); }
        break;
      case "phoneNumbers-type":
      case "phoneNumbers-value":
      case "emails-type":
        // key[0] => emails or phoneNumbers
        var key = event.target.dataset.valueName.split("-");
        newCustomer[key[0]][parseInt(key[2])][key[1]] = event.target.value;

        originalValue = this.state.customer[`${key[0]}Original`]
        if (!this.props.customerEditPermission && !_.isEqual(newCustomer[key[0]].slice(0, originalValue.length), originalValue)) { return; }

        newCustomer[`${key[0]}Original`]

        break;
      case "emails-value":
        var key = event.target.dataset.valueName.split("-");
        newCustomer.emails[parseInt(key[2])]["value"]["address"] = event.target.value;

        originalValue = this.state.customer[`${key[0]}Original`]
        if (!this.props.customerEditPermission && !_.isEqual(newCustomer[key[0]].slice(0, originalValue.length), originalValue)) { return; }
        break;
    }

    this.setState({customer: newCustomer});
  };

  addressEditPermission = () => {
    return (this.props.customerEditPermission || !this.state.customer.displayAddress);
  };

  switchEditMode = () => {
    if (this.state.processing) { return; }
    this.setState({ edit_mode: !this.state.edit_mode });
  };

  switchReservationMode = (event) => {
    event.preventDefault();
    if (this.state.processing) { return; }
    if (!this.props.shop) {
      $("#reservationManagementNoShopModal").modal("show");
      return;
    }
    if (this.state.customer.id) {
      if (this.state.customer.googleDown) {
        alert(this.props.googleDownMessage);
        return;
      }
      this.setState({ reservation_mode: !this.state.reservation_mode });
    }
  };

  switchProcessing = (callback) => {
    this.setState({ processing: true }, function() {
      if (callback) { callback(); }
    })
  };

  forceStopProcessing = () => {
    this.setState({ processing: false });
  };

  _handlePrintingPageSizeChange = (event) => {
    this.setState({[event.target.name]: event.target.value});
  };

  handlePrinting = (event) => {
    event.preventDefault();
    if (!this.state.printing_page_size) { return; }

    var url = `${this.props.printingPath}?customer_id=${this.state.selected_customer_id}&page_size=${this.state.printing_page_size}`
    window.open(url, this.state.printing_page_size);
  };

  renderMessageBar = () => {
    return (
      <MessageBar
        status={this.state.customer.googleContactMissing ? "alert-info" : ""}
        message={this.props.googleContactMissingMessage}
      />
    );
  }

  renderCustomerView = () => {
    var _this = this;

    if (this.state.reservation_mode && this.props.shop) {
      return (
        <CustomerReservationsView
          ref={(c) => this.CustomerReservationsView = c }
          customer={this.state.customer}
          switchReservationMode={this.switchReservationMode}
          customerReservationsPath={this.props.customerReservationsPath}
          switchProcessing={this.switchProcessing}
          forceStopProcessing={this.forceStopProcessing}
          stateCustomerReservationsPath={this.props.stateCustomerReservationsPath}
          editCustomerReservationsPath={this.props.editCustomerReservationsPath}
          shop={this.props.shop}
          recheckInBtn={this.props.recheckInBtn}
          checkInBtn={this.props.checkInBtn}
          checkOutBtn={this.props.checkOutBtn}
          acceptBtn={this.props.acceptBtn}
          acceptInCanceledBtn={this.props.acceptInCanceledBtn}
          pendBtn={this.props.pendBtn}
          editBtn={this.props.editBtn}
          cancelBtn={this.props.cancelBtn}
          withWarningsMessage={this.props.withWarningsMessage}
          customerDetailsReadable={this.state.customer.detailsReadable}
          groupBlankOption={this.props.groupBlankOption}
          />
      )
    }
    else if (this.state.edit_mode) {
      if (!this.state.selected_customer_id && !this.state.didSearch) {
        return (
          <div className="checking-search-bar">
            <div className="info">
              {this.props.tipBeforeNewCustomer}
            </div>
            <div>
              <i className="fa fa-search fa-2x search-symbol" aria-hidden="true"></i>
              <input type="text" id="search" placeholder="名前で検索" onKeyPress={this.SearchCustomers} />
            </div>
          </div>
        );
      }
      return (
        <CustomerInfoEdit
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
          addressEditPermission={this.addressEditPermission()}
          handleCreatedCustomer={this._handleCreatedCustomer}
          switchEditMode={this.switchEditMode}
          switchProcessing={this.switchProcessing}
          forceStopProcessing={this.forceStopProcessing}
          switchReservationMode={this.switchReservationMode}
          saveCustomerPath={this.props.saveCustomerPath}
          fetchCustomerDetails={this.fetchCustomerDetails}
          customerEditPermission={this.props.customerEditPermission}
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
          googleDownMessage={this.props.googleDownMessage}
          groupBlankOption={this.props.groupBlankOption}
          />
      )
    }
    else {
      return (
        <CustomerInfoView
          customer={this.state.updated_customer}
          switchEditMode={this.switchEditMode}
          switchReservationMode={this.switchReservationMode}
          addressLabel={this.props.addressLabel}
          phoneLabel={this.props.phoneLabel}
          emailLabel={this.props.emailLabel}
          birthdayLabel={this.props.birthdayLabel}
          memoLabel={this.props.memoLabel}
          editBtn={this.props.editBtn}
          groupBlankOption={this.props.groupBlankOption}
          />
      );
    }

  };

  renderCustomerButtons = () => {
    if (this.state.edit_mode) {
      if (!this.state.didSearch && !this.state.selected_customer_id) {
        return <div></div>
      }
      return (
        <div>
          <dl>
            <a href="#"
              onClick={this.handleCustomerCreate}
              className={`BTNyellow ${!this._isCustomerDataValid() || this.state.processing ? "disabled" : ""}`}
              >
              <dd id="NAVnewResv">
                <i className="fa fa-folder-o fa-2x"></i>
                <span>{this.props.saveBtn}</span>
              </dd>
              </a>
          </dl>
          <dl>
            {
              this.state.selected_customer_id && (
                <a href="#"
                  onClick={this.handleDeleteCustomer}
                  className={`btn btn-orange ${this.state.processing ? "disabled" : ""}`}
                  data-confirm={this.props.customerDeleteConfirmMessage}
                  >
                    <i className="fa fa-trash-o"></i>
                    <span>{this.props.deleteCustomerBtn}</span>
                </a>
              )
            }
           </dl>
         </div>
      );
    }
    else if (this.state.selected_customer_id) {
      if (this.props.fromReservation) {
        return (
          <dl>
            <a href="#" className="BTNyellow"
              onClick={this.handleAddCustomerToReservation}>
              <dd id="NAVaddCustomer">
                <i className="fa fa-user-plus fa-2x"></i>
                <span>この顧客で<br />決定する</span>
              </dd>
            </a>
          </dl>
        );
      }
      else if (this.props.reservationCreatePermission && this.props.shop) {
        return (
          <dl>
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
          </dl>
        );
      }
      else if (this.props.shop) {
        return (
          <dl>
            <a data-controller="modal" data-modal-target="#dummyModal"
              data-action="click->modal#popup" data-modal-path={this.props.reservationCreateWarningPath}
              className="BTNtarco" href="#">
              <dd id="NAVnewResv">
                <i className="fa fa-calendar-plus-o fa-2x"></i>
                <span>新規予約</span>
              </dd>
            </a>
          </dl>
        );
      }
    }
  };

  render() {
    return(
      <div>
        <ProcessingBar processing={this.state.processing} processingMessage={this.props.processingMessage} />
        {this.renderMessageBar()}
        <div id="customer" className="contents">
          <div id="resultList" className="sidel">
            <ul>
              <li className="regular">
                <span className="customer-level-symbol regular">
                  <i className="fa fa-address-card"></i>
                </span>
                <span>一般</span>
              </li>
              <li className="vip">
                <span className="customer-level-symbol vip">
                  <i className="fa fa-address-card"></i>
                </span>
                <span>VIP</span>
              </li>
            </ul>
            <CommonCustomersList
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
            <ProcessingBar processing={this.state.moreCustomerProcessing} processingMessage={this.props.processingMessage} />
            {
              this.state.selected_customer_id ? (
                <button
                  id="new-customer-btn"
                  className="BTNtarco"
                  onClick={this.newCustomerMode.bind(null, 'manual')}
                  disabled={this.state.processing} >
                  新規データ作成
                </button>
              ) : null
            }
          </div>

          {this.renderCustomerView()}

          <div id="mainNav">
            {this.renderCustomerButtons()}
            { this.props.fromReservation ? (
              <dl>
                <a href="#" className="BTNgray" onClick={this.handleWithoutCustomerToReservation}>
                  <dd id="NAVaddCustomer">
                    <i className="fa fa-chevron-left fa-2x"></i>
                    <span>選ばず戻る</span>
                  </dd>
                </a>
              </dl>
            ) : null}
            {

              this.state.selected_customer_id && !this.state.edit_mode ? (
                <dl>
                  <dd id="NAVprint">
                    <Select
                      name="printing_page_size"
                      options={this.props.printingPageSizeOptions}
                      value ={this.state.printing_page_size}
                      onChange={this._handlePrintingPageSizeChange}
                      blankOption={this.props.printingPageSizeBlankOption}
                      includeBlank={true}
                      />
                    <a onClick={this.handlePrinting} href="#"
                      className={`BTNtarco ${this.state.printing_page_size ? null : "disabled"}`}
                      title="印刷" target="_blank">
                      <i className="fa fa-print"></i>
                    </a>
                  </dd>
                </dl>
              ) : null
            }
          </div>
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
        </div>
        <footer>
          <CustomersSearchBar
            filterCustomers={this.filterCustomers}
            selectedFilterPatternNumber={this.state.selectedFilterPatternNumber}
            SearchCustomers={this.SearchCustomers} />
        </footer>
      </div>
    );
  }
};

export default CustomersDashboard;
