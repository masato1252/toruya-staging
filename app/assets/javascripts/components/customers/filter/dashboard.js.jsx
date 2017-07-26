//= require "components/customers/filter/query_sider"

"use strict";

UI.define("Customers.Filter.Dashboard", function() {
  var CustomersFilterDashboard = React.createClass({
    getInitialState: function() {
      return ({
        customers: []
      });
    },

    updateCustomers: function(customers) {
      this.setState({customers: customers});
    },

    render: function() {
      return(
        <div id="dashboard" className="contents">
          <UI.Customers.Filter.QuerySider
            {...this.props}
            updateCustomers={this.updateCustomers}
          />
          <UI.Customers.Filter.CustomersList
            {...this.props}
            customers={this.state.customers}
          />

          <div id="mainNav">
            <dl>
              <dd id="NAVsave">
                <a className="BTNtarco" href="#">
                  <i className="fa fa-floppy-o fa-2x" aria-hidden="true"></i>
                  <span>Save Filter</span>
                </a>
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
