"use strict";

import React from "react";

UI.define("Week", function() {
  return class Week extends React.Component {
    isContainedBy = (container, date) => {
      return (_.contains(container, date.date()) && date.month() === this.props.month.month())
    };

    isReservedDay = (date) => {
      return this.isContainedBy(this.props.reservationDays, date);
    };

    isHoliday = (date, wday) => {
      var month = this.props.month;
      var isWeekend = (wday === 0 && date.month() === month.month());
      return isWeekend || (this.isContainedBy(this.props.holidayDays, date));
    };

    isWorkingDay = (date, wday) => {
      if (this.isHoliday(date) && !this.props.shopWorkingOnHoliday) { return; }
      if (this.isContainedBy(this.props.offDays, date)) { return; }
      if (date.month() !== this.props.month.month()) { return; }

      if (this.props.fullTime) {
        return _.contains(this.props.shopWorkingWdays, wday);
      }
      else {
        return _.contains(this.props.staffWorkingWdays, wday) || this.isContainedBy(this.props.workingDays, date);
      }
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
          isHoliday: this.isHoliday(date, i),
          isWorkingDay: this.isWorkingDay(date, i),
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
                onClick={this.props.select.bind(null, day)}>{day.number}
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
});

export default UI.Week;
