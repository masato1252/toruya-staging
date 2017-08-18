//= require "components/customers/filter/query_sider"

"use strict";

UI.define("Customers.Filter.Dashboard", function() {
  var CustomersFilterDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: [],
        filter_name: "",
        current_saved_filter_id: "",
        customers_processing: false
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
        // _this.props.handleCreatedCustomer(result["customer"]);
        // _this.props.updateCustomers(result["customers"]);
        // _this.props.forceStopProcessing();
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
              <dd id="NAVprintAddress"><select><option>Print Address</option><option>A4</option><option>Postcard Vert</option><option>Postcard Horiz</option><option>Envelope Cho3</option></select><a href="#" className="BTNtarco" title="印刷"><i className="fa fa-print"></i></a></dd>
            </dl>
          </div>

        </div>
      );
    }
  });

  return CustomersFilterDashboard;
});
