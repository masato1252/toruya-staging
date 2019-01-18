"use strict";

import React from "react";

class ProcessingBar extends React.Component {
  static defaultProps = { processingMessage: "送信中" };

  render() {
    if (!this.props.processing) {
      return <span />
    }

    return (
      <div className="hover_alert">
        <div className="alert processing-bar">
          {this.props.processingMessage} <i className="fa fa-spinner fa-spin fa-fw" aria-hidden="true"></i>
        </div>
      </div>
    );
  }
};

export default ProcessingBar;
