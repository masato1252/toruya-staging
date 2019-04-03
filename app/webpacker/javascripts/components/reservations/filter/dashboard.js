"use strict";

import React from "react";
import axios from "axios";
import Rails from "rails-ujs";

import ReservationsFilterQuerySider from "./query_sider.js";
import ReservationsFilterReservationsList from "./reservations_list.js";

class ReservationsFilterDashboard extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      query_processing: false,
      reservations: null,
      filtered_outcome_options: this.props.filteredOutcomeOptions,
      filter_name: "",
      current_saved_filter_id: "",
      current_saved_filter_name: "",
      preset_filter_name: ""
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

  updateFilter = (hash) => {
    this.setState(hash);
  };

  updateResult = (reservations) => {
    this.setState({reservations: reservations}, () => {
      this.stopProcessing()
    });
  };

  startProcessing = () => {
    this.setState({query_processing: true});
  };

  stopProcessing = () => {
    this.setState({query_processing: false});
  };

  reset = () => {
    this.querySider.reset();
    this.updateResult([]);
  };

  saveFilter = () => {
    event.preventDefault();
    var _this = this;
    var valuesToSubmit = $(this.querySider.filterForm).serialize();

    if (this.props.canManageSavedFilter) {
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
      _this.setState({reservations: []});
    })
  };

  isResultEmpty = () => {
    return this.state.reservations === null || this.state.reservations.length === 0
  };

  renderFilterButton = () => {
    if (this.state.current_saved_filter_id) {
      return (
        <a className="BTNorange" href="#" onClick={this.deleteFilter} >
          <i className="fa fa-trash-o" aria-hidden="true"></i>
        </a>
      )
    }
    else {
      return (
        <a
          className={`BTNyellow ${this.state.filter_name && this.state.filter_name !== this.state.current_saved_filter_name? null : "disabled"}`} href="#"
          onClick={this.saveFilter} >
          <i className="fa fa-floppy-o" aria-hidden="true"></i>
        </a>
      )
    }
  };

  render() {
    return(
      <div>
        <div id="dashboard" className="contents">
          <ReservationsFilterQuerySider
            ref={(c) => {this.querySider = c}}
            {...this.props}
            updateResult={this.updateResult}
            updateFilter={this.updateFilter}
            customerFilterPath={this.props.customerFilterPath}
            startProcessing={this.startProcessing}
          />
          <ReservationsFilterReservationsList
            {...this.props}
            reservations={this.state.reservations}
            processing={this.state.query_processing}
            processingMessage={this.props.processingMessage}
          />

          <div id="mainNav">
            <dl>
              {this.isResultEmpty() ? null : (
                <div>
                  <dt>{this.props.saveFilterTitle}</dt>
                  <dd id="NAVsave">
                    <input type="text"
                      data-name="filter_name"
                      placeholder="条件名を入力"
                      className="filter-name-input"
                      value={this.state.filter_name}
                      disabled={this.isResultEmpty() || this.state.current_saved_filter_id}
                      onChange={this.onDataChange} />
                    {this.renderFilterButton()}
                  </dd>
                  <dd id="NAVrefresh">
                    <a href="#" onClick={this.reset} className="BTNgray">
                      <i className="fa fa-repeat"></i> 検索条件クリア
                    </a>
                  </dd>
                </div>
              )}
              </dl>
          </div>
        </div>
      </div>
    )
  }
};

export default ReservationsFilterDashboard
