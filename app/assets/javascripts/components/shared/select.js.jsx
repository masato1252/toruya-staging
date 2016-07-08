"use strict";

UI.define("Select", function() {
  var Select = React.createClass({
    render: function() {
      var optionsList = [];
      optionsList = this.props.options.map(function(option) {
        return <option key={option.value} value={option.value}>{option.label}</option>;
      });

      if (this.props.includeBlank) {
        optionsList.unshift(<option disabled value="" key=""> -- select an option -- </option>);
      }

      return(
        <select id={this.props.id}
                className={this.props.className}
                name={this.props.name}
                value={this.props.value}
                onChange={this.props.onChange}>
          {optionsList}
        </select>
      );
    }
  });

  return Select;
});

