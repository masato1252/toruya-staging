"use strict";

import React from "react";

var createReactClass = require("create-react-class");

UI.define("MessageBar", function() {
  var MessageBar = createReactClass({
    // status: 'alert-success', 'alert-danger', 'alert-warning', 'alert-info'
    render: function() {
      if (!this.props.status || !this.props.message) {
        return null;
      }

      return (
        <div className={`alert fade in ${this.props.status}`}>
          <button className="close" data-dismiss="alert" onClick={this.props.closeMessageBar}>x</button>
          {this.props.message}
        </div>
      );
    }
  });

  return MessageBar;
});

export default UI.MessageBar;
