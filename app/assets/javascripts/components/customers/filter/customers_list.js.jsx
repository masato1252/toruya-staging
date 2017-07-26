"use strict";

UI.define("Customers.Filter.CustomersList", function() {
  var CustomersList = React.createClass({
    renderCustomersList: function() {
      return (
        this.props.customers.map(function(customer) {
          return (
            <dl key={customer.id}>
              <dd className="status"><span className={`customer-level-symbol ${customer.rank.key}`}></span></dd>
              <dd className="customer">{customer.label}</dd>
              <dd className="address">{customer.displayAddress}</dd>
              <dd className="group">{customer.groupName}</dd>
            </dl>
          )
        })
      );
    },

    render: function() {
      return (
        <div id="resList" className="contBody">
          <dl className="tableTTL">
            <dt className="status">&nbsp;</dt>
            <dt className="customer">顧客氏名</dt>
            <dt className="address">住所</dt>
            <dt className="group">顧客台帳</dt>
          </dl>
          <div id="record">
            {this.renderCustomersList()}
          </div>
          <div className="status-list">
            <div><span className="customer-level-symbol regular"></span><span>一般</span></div>
            <div><span className="customer-level-symbol vip"></span><span>VIP</span></div>
          </div>
        </div>
      );
    }
  });

  return CustomersList;
});
