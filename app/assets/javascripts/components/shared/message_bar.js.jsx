"use strict";

UI.define("MessageBar", function() {
  var MessageBar = React.createClass({
    // status: 'alert-success', 'alert-danger', 'alert-warning', 'alert-info'
    render: function() {
      if (!this.props.status || !this.props.message) {
        return null;
      }

      return (
        <div className={`alert fade in ${this.props.status}`}>
          <button className="close" data-dismiss="alert">x</button>
          {this.props.message}
        </div>
      );
    }
  });

  return MessageBar;
});
