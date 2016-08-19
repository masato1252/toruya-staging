"use strict";

UI.define("Common.CustomerOption", function() {
  var CustomerOption = React.createClass({
    _handleClick: function() {
      if (this.props.handleCustomerSelect) {
        this.props.handleCustomerSelect(this.props.customer.value);
      }
    },

    _handleRemove: function() {
      if (this.props.handleCustomerRemove) {
        this.props.handleCustomerRemove(this.props.customer.value);
      }
    },

    render: function() {
      return(
        <dl className={`customer-option ${this.props.selected_customer_id && this.props.selected_customer_id == this.props.customer.value ? "here" : null}`}>
          <dd onClick={this._handleClick} className="customer-symbol">
            <span className={`customer-level-symbol ${this.props.customer.level}`} />
          </dd>
          <dt onClick={this._handleClick}>
            <p>{this.props.customer.label}</p>
            <p className="place">Address</p>
          </dt>
          {this.props.handleCustomerRemove ? <dd onClick={this._handleRemove}>
            <span className="customer-remove-symbol glyphicon glyphicon-remove" />
          </dd> : null}
        </dl>
      );
    }
  });

  return CustomerOption;
});

