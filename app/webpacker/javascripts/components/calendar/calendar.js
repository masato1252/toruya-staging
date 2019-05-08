"use strict";

import React from "react";
import axios from "axios";
import _ from "lodash";

import DayNames from "./day_names.js";
import Week from "./week.js";
import Select from "../shared/select.js";
var moment = require('moment-timezone');

class Calendar extends React.Component {
  constructor(props) {
    super(props);
    moment.locale('ja');

    this.startDate = this.props.selectedDate ? moment(this.props.selectedDate) : moment().startOf("day");

    this.state = {
      month: this.startDate.clone(),
      selectedDate: this.startDate.clone(),
    };
  };

  componentDidMount = () => {
    this._fetchSchedule();
  };

  componentDidUpdate = (prevProps) => {
    if (!_.isEqual(this.props.scheduleParams, prevProps.scheduleParams)) {
      this._fetchSchedule();
    }
  }

  previous = () => {
    var month = this.state.month;
    month.add(-1, "M");
    this.setState({ month: month }, this._fetchSchedule);
  };

  next = () => {
    var month = this.state.month;
    month.add(1, "M");
    this.setState({ month: month }, this._fetchSchedule);
  };

  _fetchSchedule = () => {
    var staff_id;

    if (location.search.length) {
      staff_id = location.search.replace(/\?staff_id=/, '');
    }

    const scheduleParams = _.merge({ date: this.state.month.format("YYYY-MM-DD"), staff_id: staff_id }, this.props.scheduleParams || {})

    axios({
      method: "GET",
      url: this.props.schedulePath,
      params: scheduleParams,
      responseType: "json"
    }).then((response) => {
      var result = response.data;

      this.setState({
        holidayDates: result["holiday_dates"],
        workingDates: result["working_dates"],
        reservationDates: result["reservation_dates"],
        availableBookingDates: result["available_booking_dates"]
      });
    });
  };

  select = (day) => {
    this.setState({ month: day.date, selectedDate: day.date });

    if (this.props.dateSelectedCallbackPath) {
      location = `${this.props.dateSelectedCallbackPath}/${day.date.format("YYYY-MM-DD")}${location.search}`;
    }
  };

  handleCalendarSelect = (event) => {
    event.preventDefault();
    this.setState({month: moment(event.target.value)}, this._fetchSchedule);
  };

  renderYearSelector = () => {
    var years = [];

    var yearStart = this.state.month.clone().add(-3, "Y").startOf('year')

    for (var i = 0; i <= 6; i++) {
      var newYear = yearStart.clone().add(i, "Y");
      var newYearMonth = moment({year: newYear.year(), month: this.state.month.month()});

      years.push({value: newYearMonth.format("YYYY-MM"), label: newYearMonth.format("YYYY")})
    }

    return (
      <Select
        options={years}
        value={this.state.month.format("YYYY-MM")}
        onChange={this.handleCalendarSelect}
      />);
  };

  renderMonthSelector = () => {
    var months = [];
    var yearStart = this.state.month.clone().startOf('year')

    this.props.monthNames.forEach(function(month, i) {
      var newMonth = yearStart.clone().add(i, "M");
      months.push({value: newMonth.format("YYYY-MM"), label: month})
    })

    return (
      <Select
        options={months}
        value={this.state.month.format("YYYY-MM")}
        onChange={this.handleCalendarSelect}
      />);
  };

  render() {
    return (
      <div className="calendar">
        <div className="header">
          <i className="fa fa-angle-left fa-2x" onClick={this.previous}></i>
          {this.renderYearSelector()}
          {this.renderMonthSelector()}
          <i className="fa fa-angle-right fa-2x" onClick={this.next}></i>
        </div>
        <DayNames dayNames={this.props.dayNames} />
        {this.renderWeeks()}
      </div>
    );
  };

  renderWeeks = () => {
    var weeks = [],
        done = false,
        date = this.state.month.clone().startOf("month").add("w" -1).day("Sunday"),
        monthIndex = date.month(),
        count = 0;

        while (!done) {
          weeks.push(
            <Week
              key={date.toString()}
              date={date.clone()}
              month={this.state.month}
              select={this.select}
              selected={this.state.month}
              selectedDate={this.state.selectedDate}
              holidayDates={this.state.holidayDates}
              workingDates={this.state.workingDates}
              availableBookingDates={this.state.availableBookingDates}
              reservationDates={this.state.reservationDates}
            />
          );
          date.add(1, "w");
          done = count++ > 2 && monthIndex !== date.month();
          monthIndex = date.month();
        }

        return weeks;
  }
};

export default Calendar;
