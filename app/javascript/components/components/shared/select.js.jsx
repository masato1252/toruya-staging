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
      const { includeBlank, options, prefix, blankOption, ...rest } = this.props;

      // [{label: ..., value: ...}, {...}]
      if (options.length == 0 || options[0].label) {
        optionsList = options.map(function(option, i) {
          return <option key={`${prefix}-${option.value}-${i}`} value={option.value}>{option.label}</option>;
        });
      } else {
      // [ {group_label: ..., options: [{label: ..., value: ...}]}, {...}]
        optionsList = options.map(function(group_option) {
          var nested_options = group_option.options.map(function(option) {
              return (
                <option key={`${prefix}-${option.value}`} value={option.value}>{option.label}</option>
              );
            });

          return (
              <optgroup key={group_option.group_label || group_option.groupLabel } label={group_option.group_label || group_option.groupLabel}>
                {nested_options}
              </optgroup>
            )
        });
      }

      if (includeBlank) {
        optionsList.unshift(<option value="" key="">{blankOption}</option>);
      }

      return(
        <select {...rest} >
          {optionsList}
        </select>
      );
    }
  });

  return Select;
});
