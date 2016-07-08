"use strict";

UI.define("CustomHiddenField", function() {
  var CustomHiddenField = React.createClass({
    render: function() {
      return (
        <div>
          <div>
            {this.props.label}
            <i className="fa fa-minus fa-2" aria-hidden="true"
               value={this.props.value} onClick={this.props.onClick}>
            </i>
          </div>
          <input type="hidden" value={this.props.value} name={this.props.name} />
        </div>
      )
    }
  });

  return CustomHiddenField
});
