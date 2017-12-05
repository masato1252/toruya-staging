"use strict";

import React from "react";
import "./query_sider.js";
import "./reservations_list.js";
import "../../shared/message_bar.js";
import "../../shared/select.js";
import "../../shared/printing_modal.js";

UI.define("Reservations.Filter.Dashboard", function() {
  return class ReservationsFilterDashboard extends React.Component {
    constructor(props) {
      super(props);

      this.state = {
        printing_status: "",
        query_processing: false,
        reservations: [],
        filtered_outcome_options: this.props.filteredOutcomeOptions,
        filter_name: "",
        current_saved_filter_id: "",
        current_saved_filter_name: "",
        preset_filter_name: "",
        printing_page_size: "",
        info_printing_page_size: "",
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
      this.setState({printing_page_size: "", info_printing_page_size: "", printing_status: ""});
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
        reservation_ids: _.map(this.state.reservations, function(reservation) { return reservation.id; }).join(",")
      });

      $.ajax({
        type: "POST",
        url: _this.props.printingPath, //sumbits it to the given url of the form
        data: valuesToSubmit,
        dataType: "JSON"
      }).done(function(result) {
        _this.setState(result)
        _this.reset();
        _this.setState({printing_status: "alert-info"}); // avoid user click again.
      })
    };

    saveFilter = () => {
      event.preventDefault();
      var _this = this;
      var valuesToSubmit = $(this.querySider.filterForm).serialize();

      $.ajax({
        type: "POST",
        url: _this.props.saveFilterPath, //sumbits it to the given url of the form
        data: `${valuesToSubmit}&name=${this.state.filter_name}`,
        dataType: "JSON"
      }).done(function(result) {
        _this.querySider.updateFilterOption(result, false);
        // [TODO]: Discuss the expected behavior what to do.
        // _this.querySider.reset();
      })
    };

    isResultEmpty = () => {
      return this.state.reservations.length === 0
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
          <UI.MessageBar
            status={this.state.printing_status}
            message={this.props.printingMessage}
            closeMessageBar={function() { this.setState({printing_status: ""}) }.bind(this)}
            />
          <div id="dashboard" className="contents">
            <UI.Reservations.Filter.QuerySider
              ref={(c) => {this.querySider = c}}
              {...this.props}
              updateResult={this.updateResult}
              updateFilter={this.updateFilter}
              startProcessing={this.startProcessing}
            />
            <UI.Reservations.Filter.ReservationsList
              {...this.props}
              reservations={this.state.reservations}
              processing={this.state.query_processing}
              processingMessage={this.props.processingMessage}
            />

            <div id="mainNav">
              <dl>
                {this.isResultEmpty() ? null : (
                  <div>
                    {
                      this.props.canManageSavedFilter ? (
                        <dt>{this.props.saveFilterTitle}</dt>
                      ) : null
                    }
                    {
                      this.props.canManageSavedFilter ? (
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
                      ) : null
                    }
                    <dd id="NAVrefresh">
                      <a href="#" onClick={this.reset} className="BTNgray">
                        <i className="fa fa-repeat"></i> 検索条件クリア
                      </a>
                    </dd>
                    <dt>{this.props.printingResultTitle}</dt>
                    <dd id="NAVprintList">
                      <UI.Select
                        data-name="info_printing_page_size"
                        options={this.props.infoPrintingPageSizeOptions}
                        value ={this.state.info_printing_page_size}
                        onChange={this.onDataChange}
                        blankOption={this.props.infoPrintingPageSizeBlankOption}
                        includeBlank={true}
                        />
                      <a onClick={this.handlePrinting}
                        href="#"
                        className={`BTNtarco ${this.state.info_printing_page_size && !this.isResultEmpty() ? null : "disabled"}`}
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
                  </div>
                )}
                <dd id="NAVprintFilter">
                  {this.state.filtered_outcome_options.length === 0 ? (
                    <a href="#" className="BTNtarco disabled">{this.props.noFileForPrintWording}</a>
                  ) : (
                    <a href="#" data-toggle="modal" data-target="#printing-files-modal" className="BTNtarco">
                      <i className="fa fa-file-pdf-o"></i> {this.props.filesForPrintWording}
                    </a>
                    )}
                  </dd>
                </dl>
            </div>
            <UI.PrintingModal
              {...this.props}
              filtered_outcome_options={this.state.filtered_outcome_options}
            />
          </div>
        </div>
      )
    }
  };
});

export default UI.Reservations.Filter.Dashboard
