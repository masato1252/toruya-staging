//= require "components/shared/select"
//= require "components/menu_staff_fields/selected_option_field"

"use strict";

UI.define("MenuStaffSelect", function() {
  var MenuStaffSelect = React.createClass({
    getInitialState: function() {
      return {
        options: this.props.options,
        selectedOptions: this.props.selectedOptions
      }
    },

    _handleOptionClick: function(event) {
      event.preventDefault();
      var selectedOptions = this.state.selectedOptions.slice(0);
      var originalOptions = this.state.options.slice(0);

      var result = this._toggleOptions(originalOptions, selectedOptions, event.target.value)
      selectedOptions.push(result["newOption"]);

      this.setState({selectedOptions: selectedOptions, options: _.sortBy(result["removedOptions"], "value")});
    },

    _handleSelectedOptionClick: function(event) {
      event.preventDefault();
      var originalSelectedOptions = this.state.selectedOptions.slice(0);
      var options = this.state.options.slice(0);

      var result = this._toggleOptions(originalSelectedOptions, options, event.target.value)
      options.push(result["newOption"]);

      this.setState({selectedOptions: result["removedOptions"], options: _.sortBy(options, "value")});
    },

    _toggleOptions: function(removingOptions, addingOptions, selectedValue) {
      var removedOptions = _.reject(removingOptions, function(option){ return option.value == selectedValue; });
      var newOption = _.find(removingOptions, function(option){ return option.value == selectedValue; });

      return {removedOptions: removedOptions, newOption: newOption}
    },

    render: function() {
      return (
        <div>
          <UI.Select options={this.state.options}
            value=""
            onChange={this._handleOptionClick}
            includeBlank={true}
          />
          <input type="hidden" value="" name="menu[staff_ids][]" />
          <input type="hidden" value="" name="staff[menu_ids][]" />
          <div className="selected-options">
            {this._renderSelectedOptions()}
          </div>
        </div>
      )
    },

    _renderSelectedOptions: function() {
      if (this.state.selectedOptions.length) {
        return(
          this.state.selectedOptions.map(function(option) {
            return(
              <UI.SelectedOptionField
                  key={option.value}
                  placeholder={this.props.placeholder}
                  option={option}
                  maxCustomerFieldName={this.props.maxCustomerFieldName}
                  selectedFieldName={this.props.selectedFieldName}
                  onClick={this._handleSelectedOptionClick}
                  name="" />
            );
          }.bind(this))
        )
      }
    }
  });

  return MenuStaffSelect;
});
