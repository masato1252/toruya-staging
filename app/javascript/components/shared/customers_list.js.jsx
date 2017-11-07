//= require "components/shared/customer_option"

"use strict";

UI.define("Common.CustomersList", function() {
  var CustomersList = React.createClass({
    getInitialState: function() {
      return ({
        listHeight: "60vh"
      });
    },

    componentWillMount: function() {
      this.handleMoreCustomers = _.debounce(this.props.handleMoreCustomers, 200, true)
    },

    componentDidMount: function() {
      this.setProperListHeight();
      $(window).resize(function() {
        this.setProperListHeight();
      }.bind(this));
    },

    setProperListHeight: function() {
      this.setState({listHeight: `${$(window).innerHeight() - 300} px`})
    },

    handleCustomerSelect: function(customer_id) {
      if (this.props.handleCustomerSelect) {
        this.props.handleCustomerSelect(customer_id);
      }
    },

    _atEnd: function() {
      // XXX: 1.5 is a magic number, I want to load data easier.
      return $(this.customerList).scrollTop() * 1.5 + $(this.customerList).innerHeight() >= $(this.customerList)[0].scrollHeight
    },

    _handleScroll: function() {
      if (this._atEnd()) {
        this.handleMoreCustomers();
      }
    },

    render: function() {
      var _this = this;
      var noCustomerMessage = "";

      var customerOptions = this.props.customers.map(function(customer) {
        return (
          <UI.Common.CustomerOption
            {..._this.props}
            customer={customer}
            key={customer.value} />
        );
      });

      if (this.props.noMoreCustomers) {
        if (customerOptions.length === 0) {
          noCustomerMessage = <strong className="no-more-customer">{this.props.noCustomerMessage}</strong>
        }
        else {
          noCustomerMessage = <strong className="no-more-customer">{this.props.noMoreCustomerMessage}</strong>
        }
      }

      return(
        <div
          id="customerList"
          style={{height: this.state.listHeight}}
          ref={(c) => this.customerList = c}
          onScroll={this._handleScroll}>
            {customerOptions}
            {noCustomerMessage}
          </div>
      );
    }
  });

  return CustomersList;
});
