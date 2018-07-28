"use strict";

import React from "react";

class ReservationSelectedOptionField extends React.Component {
  _handleChange = (event) => {
    this.setState({number: event.target.value})
  };

  render() {
    return (
      <div className="selected-option">
        <div>
          {this.props.option.label}
        </div>
        <div>
          <a href="#" className="btn btn-danger" value={this.props.option.value} onClick={this.props.onClick}>
            <i className="fa fa-minus-circle fa-3" aria-hidden="true" value={this.props.option.value}></i>
            Delete
          </a>
        </div>
        <input type="hidden" value={this.props.option.value} data-name="customer_id" />
      </div>
    )
  }
};

export default ReservationSelectedOptionField;
