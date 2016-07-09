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
              <input type="number"
                     onChange={this._handleChange}
                     value={this.state.number}
                     placeholder={this.props.placeholder}
                     name="menu[staff_menus_attributes][][max_customers]" />
            <a href="#" className="btn btn-danger" value={this.props.option.value} onClick={this.props.onClick}>
              <i className="fa fa-minus-circle fa-3" aria-hidden="true" value={this.props.option.value}></i>
              Delete
            </a>
          </div>
          <input type="hidden" value={this.props.option.value} name="menu[staff_menus_attributes][][staff_id]" />
        </div>
      )
    }
  });

  return CustomHiddenField
});
