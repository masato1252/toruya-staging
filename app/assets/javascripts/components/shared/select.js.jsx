"use strict";

UI.define("Select", function() {
  var Select = React.createClass({
    render: function() {
      var optionsList = this.props.options.map(function(option) {
        return <option key={option.value} value={option.value}>{option.label}</option>;
      });

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

