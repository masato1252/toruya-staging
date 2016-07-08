"use strict";

UI.define("CustomHiddenField", function() {
  var CustomHiddenField = React.createClass({
    getInitialState: function() {
      return {
        number: (this.props.option.number || 1)
      }
    },

    _handleChange: function(event) {
      this.setState({number: event.target.value})
    },

    render: function() {
      return (
        <div>
          <div>
            {this.props.option.label}
            <i className="fa fa-minus fa-2" aria-hidden="true"
               value={this.props.option.value} onClick={this.props.onClick}>
            </i>
            <input type="number" onChange={this._handleChange} value={this.state.number} name="menu[staff_menus_attributes][][max_customers]" />
          </div>
          <input type="hidden" value={this.props.option.value} name="menu[staff_menus_attributes][][staff_id]" />
        </div>
      )
    }
  });

  return CustomHiddenField
});
