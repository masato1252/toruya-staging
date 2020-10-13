"use strict";

import React from "react";
import _ from "underscore";

class Week extends React.Component {
  isWorkingDate = (date) => {
    return _.contains(this.props.workingDates, date.format("YYYY-MM-DD"));
  };

  isHoliday = (date) => {
    return _.contains(this.props.holidayDates, date.format("YYYY-MM-DD"));
  };

  isReservedDate = (date) => {
    return _.contains(this.props.reservationDates, date.format("YYYY-MM-DD"));
  };

  isAvailableBookingDate = (date) => {
    return _.contains(this.props.availableBookingDates, date.format("YYYY-MM-DD"));
  };

  isPersonalScheduleDate = (date) => {
    return _.contains(this.props.personalScheduleDates, date.format("YYYY-MM-DD"));
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
        isWorkingDate: this.isWorkingDate(date),
        isReservedDate: this.isReservedDate(date),
        isAvailableBookingDate: this.isAvailableBookingDate(date),
        isPersonalScheduleDate: this.isPersonalScheduleDate(date),
        date: date
      };

      days.push(
        <span key={day.date.toString()}
          className={
            "day" + (day.isToday ? " today" : "") +
              (day.isCurrentMonth ? "" : " different-month") +
              (day.date.isSame(this.props.selectedDate) ? " selected" : "") +
              (day.isHoliday ? " holiday" : "") +
              (day.isWorkingDate ? " workDay" : "") +
              (day.isReservedDate ? " reserved" : "") +
              (day.isAvailableBookingDate ? " booking-available" : "") +
              (day.isPersonalScheduleDate ? " personal-schedule" : "")
          }
          onClick={this.props.select.bind(null, day)}>
          <span className="number">
            {day.number}
          </span>
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
