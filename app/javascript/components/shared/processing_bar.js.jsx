"use strict";

import React from "react";
var createReactClass = require("create-react-class");

UI.define("ProcessingBar", function() {
  var ProcessingBar = createReactClass({
    getDefaultProps: function() {
      processingMessage: "Processing"
    },

    render: function() {
      if (!this.props.processing) {
        return <div />
      }

      return (
        <div className="hover_alert">
          <div className="alert processing-bar">
            {this.props.processingMessage} <i className="fa fa-spinner fa-spin fa-fw" aria-hidden="true"></i>
          </div>
        </div>
      );
    }
  });

  return ProcessingBar;
});

export default UI.ProcessingBar;
