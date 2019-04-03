"use strict";

import React from "react";

class MessageBar extends React.Component {
  // status: 'alert-success', 'alert-danger', 'alert-warning', 'alert-info'
  render() {
    if (!this.props.status || !this.props.message) {
      return null;
    }

    return (
      <div className={`alert fade in message-bar ${this.props.status}`}>
        <button className="close" data-dismiss="alert" onClick={this.props.closeMessageBar}>x</button>
        <div dangerouslySetInnerHTML={{ __html: this.props.message }} />
      </div>
    );
  }
};

export default MessageBar;
