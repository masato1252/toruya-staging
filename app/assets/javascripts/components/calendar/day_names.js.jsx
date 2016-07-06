"use strict";

UI.define("DayNames", function() {
  var DayNames = React.createClass({
    render: function() {
      return <div className="week names">
               <span className="day">日</span>
               <span className="day">月</span>
               <span className="day">火</span>
               <span className="day">水</span>
               <span className="day">木</span>
               <span className="day">金</span>
               <span className="day">土</span>
             </div>;
    }
  });

  return DayNames;
});
