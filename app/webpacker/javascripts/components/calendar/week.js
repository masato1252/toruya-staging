"use strict";

import React from "react";
import _ from "underscore";

class Week extends React.Component {
  isReservedDay = (date) => {
    return _.contains(this.props.reservationDates, date.format("YYYY-MM-DD"));
  };

  isHoliday = (date) => {
    return _.contains(this.props.holidayDates, date.format("YYYY-MM-DD"));
  };

  isWorkingDay = (date) => {
    return _.contains(this.props.workingDates, date.format("YYYY-MM-DD"));
  };

  render() {
    var days = [],
        date = this.props.date,
        month = this.props.month;

    for (var i = 0; i < 7; i++) {
      var day = {
        name: date.format("dd").substring(0, 1),
        number: date.date(),
        isCurrentMonth: date.month() === month.month(),
        isToday: date.isSame(new Date(), "day"),
        isHoliday: this.isHoliday(date),
        isWorkingDay: this.isWorkingDay(date),
        isReservedDay: this.isReservedDay(date),
        date: date
      };

      days.push(
        <span key={day.date.toString()}
          className={
            "day" + (day.isToday ? " today" : "") +
              (day.isCurrentMonth ? "" : " different-month") +
              (day.date.isSame(this.props.selectedDate) ? " selected" : "") +
              (day.isHoliday ? " holiday" : "") +
              (day.isWorkingDay ? " workDay" : "") +
              (day.isReservedDay ? " reserved" : "")
          }
          onClick={this.props.select.bind(null, day)}>
          {day.number}
        </span>
      );
      date = date.clone();
      date.add(1, "d");
    }

    return <div className="week" key={days[0].toString()}>
            {days}
           </div>
  };
};

export default Week;
