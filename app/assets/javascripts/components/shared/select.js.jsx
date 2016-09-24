"use strict";

UI.define("Select", function() {
  var Select = React.createClass({
    getDefaultProps: function() {
      return {
        prefix: "",
        blankOption: " -- select an option -- "
      };
    },

    render: function() {
      var _this = this;
      var optionsList = [];

      // [{label: ..., value: ...}, {...}]
      if (this.props.options.length == 0 || this.props.options[0].label) {
        optionsList = this.props.options.map(function(option) {
          return <option key={`${_this.props.prefix}-${option.value}`} value={option.value}>{option.label}</option>;
        });
      } else {
      // [ {group_label: ..., options: [{label: ..., value: ...}]}, {...}]
        optionsList = this.props.options.map(function(group_option) {
          var nested_options = group_option.options.map(function(option) {
              return (
                <option key={`${_this.props.prefix}-${option.value}`} value={option.value}>{option.label}</option>
              );
            });

          return (
              <optgroup key={group_option.group_label} label={group_option.group_label}>
                {nested_options}
              </optgroup>
            )
        });
      }

      if (this.props.includeBlank) {
        optionsList.unshift(<option disabled value="" key="">{this.props.blankOption}</option>);
      }

      return(
        <select {...this.props} >
          {optionsList}
        </select>
      );
    }
  });

  return Select;
});
