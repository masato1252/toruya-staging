"use strict";

import React from "react";
import Select from "../shared/select.js"
import ReservationSelectedOptionField from "../reservations/selected_option_field.js"

class ReservationCustomerSelect extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      options: this.props.options,
      selectedOptions: this.props.selectedOptions
    }
  };

  _handleOptionClick = (event) => {
    event.preventDefault();
    var selectedOptions = this.state.selectedOptions.slice(0);
    var originalOptions = this.state.options.slice(0);

    var result = this._toggleOptions(originalOptions, selectedOptions, event.target.value)
    selectedOptions.push(result["newOption"]);
    this.props.handleCustomerSelect(event);

    this.setState({selectedOptions: selectedOptions, options: _.sortBy(result["removedOptions"], "value")}, function() {
      this.props.handleCustomerSelect(event);
    });
  };

  _handleSelectedOptionClick = (event) => {
    event.preventDefault();
    var originalSelectedOptions = this.state.selectedOptions.slice(0);
    var options = this.state.options.slice(0);

    var result = this._toggleOptions(originalSelectedOptions, options, event.target.value)
    options.push(result["newOption"]);

    this.setState({selectedOptions: result["removedOptions"], options: _.sortBy(options, "value")}, function() {
      this.props.handleCustomerSelect(event);
    });
  };

  _toggleOptions = (removingOptions, addingOptions, selectedValue) => {
    var removedOptions = _.reject(removingOptions, function(option){ return option.value == selectedValue; });
    var newOption = _.find(removingOptions, function(option){ return option.value == selectedValue; });

    return {removedOptions: removedOptions, newOption: newOption}
  };

  render() {
    return (
      <div>
        <Select options={this.state.options}
          value=""
          onChange={this._handleOptionClick}
          blankOption="Select a Customer"
          includeBlank={true}
        />
        <input type="hidden" value="" name="reservation[customer_ids][]" />
        <div className="selected-options">
          {this._renderSelectedOptions()}
        </div>
      </div>
    )
  };

  _renderSelectedOptions = () => {
    if (this.state.selectedOptions.length) {
      return(
        this.state.selectedOptions.map(function(option) {
          return(
            <ReservationSelectedOptionField
                key={option.value}
                placeholder={this.props.placeholder}
                option={option}
                selectedFieldName={this.props.selectedFieldName}
                onClick={this._handleSelectedOptionClick}
                name="" />
          );
        }.bind(this))
      )
    }
  }
};

export default ReservationCustomerSelect;
