"use strict";

UI.define("ProcessingBar", function() {
  var ProcessingBar = React.createClass({
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
