"use strict";

import React from "react";

class DayNames extends React.Component {
  render() {
    var days = this.props.dayNames.map(function(name) {
      return(
        <span className="day" key={name}>
          <span className="number">
            {name}
          </span>
        </span>
      );
    });

    return (
      <div className="week names">
        {days}
      </div>
    );
  }
};

export default DayNames;
