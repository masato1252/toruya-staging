"use strict";

UI.define("Select", function() {
  var Select = React.createClass({
    getDefaultProps: function() {
      return {
        blankOption: " -- select an option -- "
      };
    },

    render: function() {
      var optionsList = [];
      optionsList = this.props.options.map(function(option) {
        return <option key={option.value} value={option.value}>{option.label}</option>;
      });

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

