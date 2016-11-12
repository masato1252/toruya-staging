"use strict";

UI.define("ProcessingBar", function() {
  var ProcessingBar = React.createClass({
    render: function() {
      if (!this.props.processing) {
        return <div />
      }

      return (
        <div className="alert processing-bar">
          Processing <i className="fa fa-spinner fa-spin fa-fw" aria-hidden="true"></i>
        </div>
      );
    }
  });

  return ProcessingBar;
});
