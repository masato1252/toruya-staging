"use strict";

UI.define("Common.CustomerOption", function() {
  var CustomerOption = React.createClass({
    _handleClick: function() {
      if (this.props.handleCustomerSelect) {
        this.props.handleCustomerSelect(this.props.customer.value)
      }
    },

    render: function() {
      var customer_id = this.props.customer.value

      return(
        <dl className="customer-option">
          <dd onClick={this._handleClick} className="customer-symbol">
            <span className="customer-level-symbol regular" />
          </dd>
          <dt onClick={this._handleClick}>
            <p>{this.props.customer["label"]}</p>
            <p class="place">Address</p>
          </dt>
          <dd onClick={this.props.handleCustomerRemove.bind(null, customer_id)}>
            <span className="customer-remove-symbol glyphicon glyphicon-remove" />
          </dd>
        </dl>
      );
    }
  });

  return CustomerOption;
});

