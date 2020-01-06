"use strict";

import React from "react";
import _ from "underscore";
import axios from "axios";
import Rails from "rails-ujs";

import CustomersFilterQuerySider from "./query_sider.js";
import FilterCustomersList from "./customers_list.js";
import MessageBar from "shared/message_bar.js";
import Select from "shared/select.js";
import PrintingModal from "../../common/printing_modal.js";

class CustomersFilterDashboard extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      customers: [],
      filter_name: "",
      current_saved_filter_id: "",
      current_saved_filter_name: "",
      preset_filter_name: "",
      printing_page_size: "",
      info_printing_page_size: "",
      customers_processing: false,
      filtered_outcome_options: this.props.filteredOutcomeOptions
    }
  };

  componentDidMount() {
    let properHeight = window.innerHeight - $("header").innerHeight() - 50;

    $(".contents").height(properHeight);
    $("#searchKeys").height(properHeight);
  };

  onDataChange = (event) => {
    let stateName = event.target.dataset.name;
    let stateValue = event.target.dataset.value || event.target.value;

    this.setState({[stateName]: stateValue});
  };

  updateFilter = (target, value) => {
    this.setState({ [target]: value });
  };

  updateCustomers = (customers) => {
    this.setState({customers: customers}, function() {
      this.stopProcessing()
    }.bind(this));
  };

  startProcessing = () => {
    this.setState({customers_processing: true});
  };

  stopProcessing = () => {
    this.setState({customers_processing: false});
  };

  saveFilter = () => {
    event.preventDefault();
    if (this.props.canManageSavedFilter) {
      var _this = this;
      var valuesToSubmit = $(this.querySider.filterForm).serialize();

      axios({
        method: "POST",
        url: _this.props.saveFilterPath, //sumbits it to the given url of the form
        data: `${valuesToSubmit}&name=${this.state.filter_name}`,
        responseType: "json"
      }).then(function(response) {
        _this.querySider.updateFilterOption(response.data, false);
      })
    } else {
      // Show popup for admin/staff
      let upgradeModal;

      if (this.props.isAdmin) {
        upgradeModal = $("#adminUpgradeSavedFilterModal");
      } else {
        upgradeModal = $("#staffUpgradeSavedFilterModal");
      }

      upgradeModal.modal("show");
    }
  };

  reset = () => {
    this.querySider.reset();
    this.updateCustomers([]);
    this.setState({printing_page_size: "", info_printing_page_size: "", printing_status: ""});
  };

  deleteFilter = () => {
    event.preventDefault();
    var _this = this;

    axios({
      method: "DELETE",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: _this.props.deleteFilterPath, //sumbits it to the given url of the form
      data: { id: this.state.current_saved_filter_id },
      responseType: "json"
    }).then(function(response) {
      _this.querySider.updateFilterOption(response.data, false);
      _this.reset();
      _this.setState({customers: []});
    })
  };

  handlePrinting = (event) => {
    event.preventDefault();
    var _this = this;

    if (!this.state[event.target.dataset.pageSizeName]) { return; }

    var valuesToSubmit = $(this.querySider.filterForm).serialize() + '&' + $.param({
      filtered_outcome: {
        page_size: this.state[event.target.dataset.pageSizeName],
        filter_id: this.state.current_saved_filter_id,
        name: this.state.current_saved_filter_name || this.state.preset_filter_name,
        outcome_type: event.target.dataset.printingType,
      },
      customer_ids: _.map(this.state.customers, function(customer) { return customer.id; }).join(",")
    });

    axios({
      method: "POST",
      url: _this.props.printingPath, //sumbits it to the given url of the form
      data: valuesToSubmit,
      responseType: "JSON"
    }).then(function(response) {
      _this.setState(response.data)
      _this.reset();
      _this.setState({printing_status: "alert-info"}); // avoid user click again.
    })
  };

  isCustomersEmpty = () => {
    return this.state.customers.length === 0
  };

  renderFilterButton = () => {
    if (this.state.current_saved_filter_id) {
      return (
        <a className="BTNorange" href="#" onClick={this.deleteFilter} >
          <i className="fa fa-trash" aria-hidden="true"></i>
        </a>
      )
    }
    else {
      return (
        <a
          className={`BTNyellow ${this.state.filter_name && this.state.filter_name !== this.state.current_saved_filter_name? null : "disabled"}`} href="#"
          onClick={this.saveFilter} >
          <i className="fa fa-save" aria-hidden="true"></i>
        </a>
      )
    }
  };

  render() {
    return(
      <div>
        <MessageBar
          status={this.state.printing_status}
          message={this.props.printingMessage}
          closeMessageBar={function() { this.setState({printing_status: ""}) }.bind(this)}
          />
        <div id="dashboard" className="contents">
          <CustomersFilterQuerySider
            ref={(c) => {this.querySider = c}}
            {...this.props}
            updateCustomers={this.updateCustomers}
            updateFilter={this.updateFilter}
            reservationFilterPath={this.props.reservationFilterPath}
            startProcessing={this.startProcessing}
          />
          <FilterCustomersList
            {...this.props}
            customers={this.state.customers}
            processing={this.state.customers_processing}
            processingMessage={this.props.processingMessage}
          />

          <div id="mainNav">
            <dl>
              {this.isCustomersEmpty() ? null : (
                <div>
                  <dt>{this.props.saveFilterTitle}</dt>
                  <dd id="NAVsave">
                    <input type="text"
                      data-name="filter_name"
                      placeholder="条件名を入力"
                      className="filter-name-input"
                      value={this.state.filter_name}
                      disabled={this.isCustomersEmpty() || this.state.current_saved_filter_id}
                      onChange={this.onDataChange} />
                    {this.renderFilterButton()}
                  </dd>
                  <dd id="NAVrefresh">
                    <a href="#" onClick={this.reset} className="BTNgray">
                      <i className="fa fa-repeat"></i> 検索条件クリア
                    </a>
                  </dd>
                  <dt>{this.props.printingResultTitle}</dt>
                  <dd id="NAVprintList">
                    <Select
                      data-name="info_printing_page_size"
                      options={this.props.infoPrintingPageSizeOptions}
                      value ={this.state.info_printing_page_size}
                      onChange={this.onDataChange}
                      blankOption={this.props.infoPrintingPageSizeBlankOption}
                      includeBlank={true}
                      />
                    <a onClick={this.handlePrinting}
                      href="#"
                      className={`BTNtarco ${this.state.info_printing_page_size && !this.isCustomersEmpty() ? null : "disabled"}`}
                      title="印刷"
                      data-printing-type={this.props.infoPrintingType}
                      data-page-size-name="info_printing_page_size"
                      target="_blank">
                      <i className="fa fa-print"
                        data-printing-type={this.props.infoPrintingType}
                        data-page-size-name="info_printing_page_size">
                      </i>
                    </a>
                  </dd>
                  <dd id="NAVprintAddress">
                    <Select
                      data-name="printing_page_size"
                      options={this.props.printingPageSizeOptions}
                      value ={this.state.printing_page_size}
                      onChange={this.onDataChange}
                      blankOption={this.props.printingPageSizeBlankOption}
                      includeBlank={true}
                      />
                    <a onClick={this.handlePrinting}
                      href="#"
                      className={`BTNtarco ${this.state.printing_page_size && !this.isCustomersEmpty() ? null : "disabled"}`}
                      title="印刷"
                      data-printing-type={this.props.addressPrintingType}
                      data-page-size-name="printing_page_size"
                      target="_blank">
                      <i className="fa fa-print"
                        data-printing-type={this.props.addressPrintingType}
                        data-page-size-name="printing_page_size">
                      </i>
                    </a>
                  </dd>
                </div>
              )}
              <dd id="NAVprintFilter">
                {this.state.filtered_outcome_options.length === 0 ? (
                  <a href="#" className="BTNtarco disabled">{this.props.noFileForPrintWording}</a>
                ) : (
                  <a href="#" data-toggle="modal" data-target="#printing-files-modal" className="BTNtarco">
                    <i className="fa fa-file-pdf"></i> {this.props.filesForPrintWording}
                  </a>
                  )}
                </dd>
              </dl>
          </div>
          <PrintingModal
            {...this.props}
            filtered_outcome_options={this.state.filtered_outcome_options}
          />
        </div>
      </div>
    );
  }
};

export default CustomersFilterDashboard
