//= require "components/customers/filter/query_sider"

"use strict";

UI.define("Customers.Filter.Dashboard", function() {
  var CustomersFilterDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: [],
        filter_name: "",
        current_saved_filter_id: "",
        printing_page_size: "",
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
        _this.querySider.reset();
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

      if (!this.state.printing_page_size) { return; }

      var valuesToSubmit = $(this.querySider.filterForm).serialize() + '&' + $.param({
        page_size: this.state.printing_page_size,
        filter_id: this.state.current_saved_filter_id,
        customer_ids: _.map(this.state.customers, function(customer) { return customer.id; }).join(",")
      });

      $.ajax({
        type: "POST",
        url: _this.props.printingPath, //sumbits it to the given url of the form
        data: valuesToSubmit,
        dataType: "JSON"
      }).done(function(result) {
        _this.setState({printing_page_size: ""}); // avoid user click again.
        // _this.props.handleCreatedCustomer(result["customer"]);
        // _this.props.updateCustomers(result["customers"]);
        // _this.props.forceStopProcessing();
      })
    },

    loadFilteredOutcome: function(event) {
      event.preventDefault();

      var _this = this;
      _this.startProcessing();

      $.ajax({
        type: "GET",
        url: _this.props.fetchFilteredOutcomePath,
        data: { id: event.target.dataset.value },
        dataType: "JSON"
      }).success(function(result) {
        _this.querySider.updateFilterOption(result);
      }).always(function() {
      });
    },

    renderDeleteFilterButton: function() {
      if (this.state.current_saved_filter_id) {
        return (
          <a className="BTNtarco" href="#" onClick={this.deleteFilter} >
            <i className="fa fa-minus fa-2x" aria-hidden="true"></i>
            <span>Delete Filter</span>
          </a>
        )
      }
    },

    renderFilteredOutcomes: function() {
      return (
        <div className="filtered-outcomes">
          {
            this.state.filtered_outcome_options.map(function(outcome) {
              return (
                <div className="filtered-outcome" key={outcome.id}>
                  <div>
                    <a href={outcome.fileUrl} target="_blank">
                      {outcome.name}
                    </a>
                  </div>
                  <div>
                    <span className={["filter-outcome-state", outcome.state].join(" ")}></span>
                    <i className="fa fa-search" data-value={outcome.id} onClick={this.loadFilteredOutcome}></i>
                  </div>
                </div>
              )
            }.bind(this))
          }
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
              <dd id="NAVsave">
                {
                  this.state.customers.length === 0 ? null : (
                    <input type="text"
                       data-name="filter_name"
                       placeholder="Write Your Filter Name"
                       className="filter-name-input"
                       value={this.state.filter_name}
                       onChange={this.onDataChange} />
                  )
                }
                <a className={`BTNtarco ${this.state.filter_name ? null : "disabled"}`} href="#"
                  onClick={this.saveFilter} >
                  <i className="fa fa-floppy-o fa-2x" aria-hidden="true"></i>
                  <span>Save Filter</span>
                </a>
              </dd>
              <dd id="NAVdelete">
                {this.renderDeleteFilterButton()}
              </dd>
              <dd id="NAVprintList"><select><option>Print List</option><option>A4</option></select><a href="#" className="BTNtarco" title="印刷"><i className="fa fa-print"></i></a></dd>
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
                  className={`BTNtarco ${this.state.printing_page_size && this.state.customers.length > 0 ? null : "disabled"}`}
                  title="印刷" target="_blank">
                  <i className="fa fa-print"></i>
                </a>
               </dd>
               <dd id="NAVprintOutcome">
                 {this.renderFilteredOutcomes()}
              </dd>
            </dl>
          </div>

        </div>
      );
    }
  });

  return CustomersFilterDashboard;
});
