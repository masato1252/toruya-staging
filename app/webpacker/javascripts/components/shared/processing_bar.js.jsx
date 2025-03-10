"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

class ProcessingBar extends React.Component {
  static defaultProps = { processingMessage: I18n.t("common.processing") };

  render() {
    if (!this.props.processing) {
      return <span />
    }

    return (
      <div className="hover_alert">
        <div className="modal-alert processing-bar">
          {this.props.processingMessage} <i className="fa fa-spinner fa-spin fa-fw" aria-hidden="true"></i>
        </div>
      </div>
    );
  }
};

export default ProcessingBar;
