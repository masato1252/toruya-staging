//= require "components/customers/filter/query_sider"
//= require "components/shared/message_bar"

"use strict";

UI.define("Customers.Filter.Dashboard", function() {
  var CustomersFilterDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: [],
        filter_name: "",
        current_saved_filter_id: "",
        current_saved_filter_name: "",
        printing_page_size: "",
        info_printing_page_size: "",
        customers_processing: false,
        filtered_outcome_options: this.props.filteredOutcomeOptions
      });
    },

    componentDidMount: function() {
      let properHeight = window.innerHeight - $("header").innerHeight() - 50;

      $(".contents").height(properHeight);
      $("#searchKeys").height(properHeight);
    },

    onDataChange: function(event) {
      let stateName = event.target.dataset.name;
      let stateValue = event.target.dataset.value || event.target.value;

      this.setState({[stateName]: stateValue});
    },

    updateFilter: function(target, value) {
      this.setState({ [target]: value });
    },

    updateCustomers: function(customers) {
      this.setState({customers: customers}, function() {
        this.stopProcessing()
      }.bind(this));
    },

    startProcessing: function() {
      this.setState({customers_processing: true});
    },

    stopProcessing: function() {
      this.setState({customers_processing: false});
    },

    saveFilter: function() {
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
    },

    reset: function() {
      this.querySider.reset();
      this.updateCustomers([]);
    },

    deleteFilter: function() {
      event.preventDefault();
      var _this = this;

      $.ajax({
        type: "POST",
        url: _this.props.deleteFilterPath, //sumbits it to the given url of the form
        data: { _method: "delete", id: this.state.current_saved_filter_id },
        dataType: "JSON"
      }).done(function(result) {
        _this.querySider.updateFilterOption(result, false);
        _this.reset();
        _this.setState({customers: []});
        // _this.props.forceStopProcessing();
      })
    },

    handlePrinting: function(event) {
      event.preventDefault();
      var _this = this;

      if (!this.state[event.target.dataset.pageSizeName]) { return; }

      var valuesToSubmit = $(this.querySider.filterForm).serialize() + '&' + $.param({
        filtered_outcome: {
          page_size: this.state[event.target.dataset.pageSizeName],
          filter_id: this.state.current_saved_filter_id,
          outcome_type: event.target.dataset.printingType,
        },
        customer_ids: _.map(this.state.customers, function(customer) { return customer.id; }).join(",")
      });

      $.ajax({
        type: "POST",
        url: _this.props.printingPath, //sumbits it to the given url of the form
        data: valuesToSubmit,
        dataType: "JSON"
      }).done(function(result) {
        _this.setState({printing_page_size: "", info_printing_page_size: "", printing_status: "alert-info"}); // avoid user click again.
        _this.setState(result)
        // _this.props.handleCreatedCustomer(result["customer"]);
        // _this.props.updateCustomers(result["customers"]);
        // _this.props.forceStopProcessing();
      })
    },

    isCustomersEmpty: function() {
      return this.state.customers.length === 0
    },

    renderFilterButton: function() {
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
    },

    renderFilteredOutcomes: function() {
      return (
        <div id="searchPrint">
          <dl className="tableTTL">
            <dt className="status">&nbsp;</dt>
            <dt className="filterName">{this.props.printingHeaderFilterName}</dt>
            <dt className="type">{this.props.printingHeaderFileType}</dt>
            <dt className="create">{this.props.printingHeaderCreatedDate}</dt>
            <dt className="exparation">{this.props.printingHeaderExpiredDate}</dt>
            <dt className="function"></dt>
          </dl>
          <div id="files">
            {
              this.state.filtered_outcome_options.map(function(outcome) {
                return (
                  <dl key={outcome.id}>
                    <dd className="status">
                      {outcome.state === "processing" ? (
                        <i className="fa fa-hourglass-half"></i>
                      ) : (
                        <i className="fa fa-print"></i>
                      )}
                    </dd>
                    <dd className="filterName">{outcome.name}</dd>
                    <dd className="type">{outcome.type}</dd>
                    <dd className="create">{outcome.createdDate}</dd>
                    <dd className="exparation">{outcome.expiredDate}</dd>
                    <dd className="function">
                      {outcome.fileUrl ? (
                        <a href={outcome.fileUrl} className="BTNtarco" target="_blank">{this.props.printBtn}</a>
                      ) : null}
                    </dd>
                  </dl>
                )
              }.bind(this))
            }
          </div>
        </div>
      )
    },

    render: function() {
      return(
        <div>
          <UI.MessageBar
            status={this.state.printing_status}
            message={this.props.printingMessage} />
          <div id="dashboard" className="contents">
            <UI.Customers.Filter.QuerySider
              ref={(c) => {this.querySider = c}}
              {...this.props}
              updateCustomers={this.updateCustomers}
              updateFilter={this.updateFilter}
              startProcessing={this.startProcessing}
            />
            <UI.Customers.Filter.CustomersList
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
                      <UI.Select
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
                      <i className="fa fa-file-pdf-o"></i> {this.props.filesForPrintWording}
                    </a>
                    )}
                  </dd>
                </dl>
            </div>
            <div className="modal fade" id="printing-files-modal" tabIndex="-1" role="dialog">
              <div className="modal-dialog" role="document">
                <div className="modal-content">
                  <div className="modal-header">
                    <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                      <span aria-hidden="true">×</span>
                    </button>
                    <h4 className="modal-title" id="myModalLabel">
                      <i className="fa fa-database-o" aria-hidden="true"></i>{this.props.filesForPrintWording}
                      </h4>
                    </div>
                    <div className="modal-body">
                      {this.renderFilteredOutcomes()}
                    </div>
                    <div className="modal-footer">
                      <dl>
                        <dd><a href="#" className="btn BTNtarco" data-dismiss="modal">{this.props.closeButton}</a></dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>
          </div>
        </div>
      );
    }
  });

  return CustomersFilterDashboard;
});
