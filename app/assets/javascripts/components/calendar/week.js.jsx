"use strict";

UI.define("Week", function() {
  var Week = React.createClass({
    render: function() {
      var days = [],
          date = this.props.date,
          month = this.props.month;

      for (var i = 0; i < 7; i++) {
        var day = {
          name: date.format("dd").substring(0, 1),
          number: date.date(),
          isCurrentMonth: date.month() === month.month(),
          isToday: date.isSame(new Date(), "day"),
          isWeekend: (i === 0 || i === 6),
          isHoliday: _.contains(this.props.holidayDays, date.date()),
          date: date
        };

        days.push(
          <span key={day.date.toString()}
                className={"day" + (day.isToday ? " today" : "") + (day.isCurrentMonth ? "" : " different-month") + (day.date.isSame(this.props.selectedDate) ? " selected" : "") + ((day.isWeekend || day.isHoliday) ? " holiday" : "")}
                onClick={this.props.select.bind(null, day)}>{day.number}
          </span>
        );
        date = date.clone();
        date.add(1, "d");
      }

      return <div className="week" key={days[0].toString()}>
              {days}
             </div>
    }
  });

  return Week;
});
