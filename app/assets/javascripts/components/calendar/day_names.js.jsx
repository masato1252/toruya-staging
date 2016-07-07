"use strict";

UI.define("DayNames", function() {
  var DayNames = React.createClass({
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
