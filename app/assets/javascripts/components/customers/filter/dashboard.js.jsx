//= require "components/customers/filter/query_sider"

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
      $(".contents").height(window.innerHeight - $("header").innerHeight() - 50);
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
        _this.querySider.reset();
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
        _this.setState({printing_page_size: "", info_printing_page_size: ""}); // avoid user click again.
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
            <dt className="filterName">Filter Name</dt>
            <dt className="type">File Type</dt>
            <dt className="create">Proceded on</dt>
            <dt className="exparation">Expire on</dt>
            <dt className="function"></dt>
          </dl>
          <div id="files">
            {
              this.state.filtered_outcome_options.map(function(outcome) {
                return (
                  <dl>
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
                        <a href={outcome.fileUrl} target="_blank" className="BTNtarco">PRINT</a>
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
                  <dt>Save Filter</dt>
                  <dd id="NAVsave">
                    <input type="text"
                      data-name="filter_name"
                      placeholder="ファイル名を入力"
                      className="filter-name-input"
                      value={this.state.filter_name}
                      disabled={this.isCustomersEmpty()}
                      onChange={this.onDataChange} />
                    {this.renderFilterButton()}
                  </dd>
                  <dt>Print Results</dt>
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
          <div className="modal fade" id="printing-files-modal" tabindex="-1" role="dialog">
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
      );
    }
  });

  return CustomersFilterDashboard;
});
