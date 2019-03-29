"use strict";

import React from "react";

class Select extends React.Component {
  static defaultProps = {
    prefix: "",
    blankOption: "オプションを選択"
  };

  render() {
    var _this = this;
    var optionsList = [];
    const { includeBlank, options, prefix, blankOption, ...rest } = this.props;

    // [{label: ..., value: ...}, {...}]
    if (options.length == 0 || options[0].label) {
      optionsList = options.map(function(option, i) {
        return <option key={`${prefix}-${option.value}-${i}`} value={option.value}>{option.label}</option>;
      });
    } else {
    // [ {label: ..., options: [{label: ..., value: ...}]}, {...}]
      optionsList = options.map(function(group_option) {
        var nested_options = group_option.options.map(function(option) {
            return (
              <option key={`${prefix}-${option.value}`} value={option.value}>{option.label}</option>
            );
          });

        return (
            <optgroup key={group_option.label} label={group_option.label}>
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
};

export default Select;
