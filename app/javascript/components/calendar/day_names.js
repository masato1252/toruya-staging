"use strict";

import React from "react";
var createReactClass = require('create-react-class');

UI.define("DayNames", function() {
  var DayNames = createReactClass({
    render: function() {
      var days = this.props.dayNames.map(function(name) {
        return(
          <span className="day" key={name}>{name}</span>
        );
      });
      return <div className="week names">
              {days}
             </div>;
    }
  });

  return DayNames;
});

export default UI.DayNames;
