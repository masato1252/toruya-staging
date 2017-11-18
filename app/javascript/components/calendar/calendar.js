"use strict";

import React from "react";
import "./day_names.js";
import "./week.js";
import "../shared/select.js";
var moment = require('moment-timezone');
var createReactClass = require('create-react-class');

UI.define("Calendar", function() {
  var Calendar = createReactClass({
    getInitialState: function() {
      this.startDate = this.props.selectedDate ? moment(this.props.selectedDate) : moment().startOf("day");

      return {
        month: this.startDate.clone(),
        selectedDate: this.startDate.clone(),
        holidayDays: this.props.holidayDays,
        fullTime: this.props.fullTime,
        shopWorkingWdays: this.props.shopWorkingWdays,
        shopWorkingOnHoliday: this.props.shopWorkingOnHoliday,
        staffWorkingWdays: this.props.staffWorkingWdays,
        workingDays: this.props.workingDays,
        offDays: this.props.offDays,
        reservationDays: this.props.reservationDays
      };
    },

    previous: function() {
      let _this = this;
      var month = this.state.month;
      month.add(-1, "M");
      this.setState({ month: month }, _this._fetchWorkingSchedule);
    },

    next: function() {
      let _this = this;
      var month = this.state.month;
      month.add(1, "M");
      this.setState({ month: month }, _this._fetchWorkingSchedule);
    },

    _fetchWorkingSchedule: function() {
      let _this = this;
      var staff_id;

      if (location.search.length) {
        staff_id = location.search.replace(/\?staff_id=/, '');
      }

      $.ajax({
        type: "GET",
        url: this.props.workingSchedulePath,
        data: { shop_id: this.props.shopId, date: this.state.month.format("YYYY-MM-DD"), staff_id: staff_id },
        dataType: "JSON"
      }).success(function(result) {
        _this.setState({
          holidayDays: result["holiday_days"],
          fullTime: result["full_time"],
          shopWorkingWdays: result["shop_working_wdays"],
          shopWorkingOnHoliday: result["shop_working_on_holiday"],
          staffWorkingWdays: result["staff_working_wdays"],
          workingDays: result["working_days"],
          offDays: result["off_days"],
          reservationDays: result["reservation_days"]
        });
      });
    },

    select: function(day) {
      this.setState({ month: day.date, selectedDate: day.date });
      location = `${this.props.reservationsPath}/${day.date.format("YYYY-MM-DD")}${location.search}`;
    },

    handleCalendarSelect: function(event) {
      event.preventDefault();
      this.setState({month: moment(event.target.value)}, this._fetchWorkingSchedule);
    },

    renderYearSelector: function() {
      var years = [];

      var yearStart = this.state.month.clone().add(-3, "Y").startOf('year')

      for (var i = 0; i <= 6; i++) {
        var newYear = yearStart.clone().add(i, "Y");
        var newYearMonth = moment({year: newYear.year(), month: this.state.month.month()});

        years.push({value: newYearMonth.format("YYYY-MM"), label: newYearMonth.format("YYYY")})
      }

      return (
        <UI.Select
          options={years}
          value={this.state.month.format("YYYY-MM")}
          onChange={this.handleCalendarSelect}
        />);
    },

    renderMonthSelector: function () {
      var months = [];
      var yearStart = this.state.month.clone().startOf('year')

      this.props.monthNames.forEach(function(month, i) {
        var newMonth = yearStart.clone().add(i, "M");
        months.push({value: newMonth.format("YYYY-MM"), label: month})
      })

      return (
        <UI.Select
          options={months}
          value={this.state.month.format("YYYY-MM")}
          onChange={this.handleCalendarSelect}
        />);
    },

    render: function() {
      return <div>
              <div className="header">
                <i className="fa fa-angle-left fa-2x" onClick={this.previous}></i>
                  {this.renderYearSelector()}
                  {this.renderMonthSelector()}
                <i className="fa fa-angle-right fa-2x" onClick={this.next}></i>
              </div>
              <UI.DayNames dayNames={this.props.dayNames} />
              {this.renderWeeks()}
             </div>;
    },

    renderWeeks: function() {
      var weeks = [],
          done = false,
          date = this.state.month.clone().startOf("month").add("w" -1).day("Sunday"),
          monthIndex = date.month(),
          count = 0;

          while (!done) {
            weeks.push(<UI.Week key={date.toString()}
                                date={date.clone()}
                                month={this.state.month}
                                select={this.select}
                                selectedDate={this.state.selectedDate}
                                holidayDays={this.state.holidayDays}
                                fullTime={this.state.fullTime}
                                shopWorkingWdays={this.state.shopWorkingWdays}
                                shopWorkingOnHoliday={this.state.shopWorkingOnHoliday}
                                staffWorkingWdays={this.state.staffWorkingWdays}
                                workingDays={this.state.workingDays}
                                offDays={this.state.offDays}
                                reservationDays={this.state.reservationDays}
                                selected={this.state.month} />);
            date.add(1, "w");
            done = count++ > 2 && monthIndex !== date.month();
            monthIndex = date.month();
          }

          return weeks;
    }
  });

  return Calendar;
});

export default UI.Calendar;
