"use strict";

import React, { useEffect, useState, useMemo, useRef } from "react";
import _ from "lodash";
import moment from "moment-timezone"

import DayNames from "./day_names.js";
import Week from "./week.js";
import Select from "../select.js";
import useSchedule from "./use_schedule";
import { getMomentLocale } from "libraries/helper.js";

const Calendar = ({locale = 'ja', ...props}) => {
  moment.locale(getMomentLocale(locale));
  let staff_id;
  const startDate = props.selectedDate ? moment(props.selectedDate) : moment().startOf("day");

  if (location.search.length) {
    staff_id = location.search.replace(/\?staff_id=/, '');
  }

  const [state, setState] = useState({
    month: startDate.clone(),
    selectedDate: props.skip_default_date ? null : startDate.clone()
  })

  const prevParamsRef = useRef(null);

  const scheduleParams = useMemo(() => {
    const newParams = _.merge({
      date: state.month.clone().startOf('month').format("YYYY-MM-DD"),
      staff_id: staff_id
    }, props.scheduleParams || {});

    // Convert to string for comparison
    const paramsString = JSON.stringify(newParams);

    // Only return new params if they're actually different
    if (prevParamsRef.current !== paramsString) {
      prevParamsRef.current = paramsString;
      return newParams;
    }

    // Return the previous params object to maintain reference equality
    return JSON.parse(prevParamsRef.current);
  }, [state.month.format('YYYY-MM'), staff_id, props.scheduleParams]);

  const { isLoading, schedules } = useSchedule({url: props.schedulePath, scheduleParams: scheduleParams});

  useEffect(() => {
    if (props.dateSelectedCallback && !props.skip_default_date) {
      props.dateSelectedCallback(startDate.format("YYYY-MM-DD"))
    }
  }, [])

  useEffect(() => {
    if (props.calendarChangedCallback) {
      props.calendarChangedCallback(state)
    }
  }, [state])

  const previous = () => {
    var month = state.month.clone();
    month.add(-1, "M");
    setState({ ...state, month: month })
  };

  const next = () => {
    var month = state.month.clone();
    month.add(1, "M");
    setState({ ...state, month: month })
  };

  const select = (day) => {
    // Only update month if the selected date is in a different month
    const newMonth = day.date.month() !== state.month.month() || day.date.year() !== state.month.year()
      ? day.date.clone().startOf('month')
      : state.month;

    setState({...state, month: newMonth, selectedDate: day.date });

    if (props.dateSelectedCallback) {
      props.dateSelectedCallback(day.date.format("YYYY-MM-DD"))
    }
    else if (props.dateSelectedCallbackPath) {
      let params = new URLSearchParams(location.search)
      params.set("schedule_display_start_date", day.date.clone().add(-1, "day").format("YYYY-MM-DD"))
      location = `${props.dateSelectedCallbackPath}/${day.date.format("YYYY-MM-DD")}?${params.toString()}`;
    }
  };

  const handleCalendarSelect = (event) => {
    event.preventDefault();
    setState({...state, month: moment(event.target.value)});
  };

  const renderYearSelector = () => {
    var years = [];

    var yearStart = state.month.clone().add(-3, "Y").startOf('year')

    for (var i = 0; i <= 6; i++) {
      var newYear = yearStart.clone().add(i, "Y");
      var newYearMonth = moment({year: newYear.year(), month: state.month.month()});

      years.push({value: newYearMonth.format("YYYY-MM"), label: newYearMonth.format("YYYY")})
    }

    return (
      <Select
        options={years}
        value={state.month.format("YYYY-MM")}
        onChange={handleCalendarSelect}
      />);
  };

  const renderMonthSelector = () => {
    var months = [];
    var yearStart = state.month.clone().startOf('year')

    props.monthNames.forEach(function(month, i) {
      var newMonth = yearStart.clone().add(i, "M");
      months.push({value: newMonth.format("YYYY-MM"), label: month})
    })

    return (
      <Select
        options={months}
        value={state.month.format("YYYY-MM")}
        onChange={handleCalendarSelect}
      />);
  };

  const renderWeeks = () => {
    var weeks = [],
      done = false,
      date = state.month.clone().startOf("month").add("w" -1).day("Sunday"),
      monthIndex = date.month(),
      count = 0;

    while (!done) {
      weeks.push(
        <Week
          key={date.toString()}
          date={date.clone()}
          month={state.month}
          select={select}
          selected={state.month}
          selectedDate={state.selectedDate}
          holidayDates={schedules.holiday_dates}
          workingDates={schedules.working_dates}
          availableBookingDates={schedules.available_booking_dates}
          personalScheduleDates={schedules.personal_schedule_dates}
          reservationDates={schedules.reservation_dates}
        />
      );
      date.add(1, "w");
      done = count++ > 2 && monthIndex !== date.month();
      monthIndex = date.month();
    }

    return weeks;
  }

  if (isLoading) {
    return (
      <div className="calendar-loading">
        <i className="fa fa-spinner fa-spin fa-fw fa-3x" aria-hidden="true"></i>
      </div>
    );
  }

  return (
    <div className="calendar">
      <div className="header">
        <i className="fa fa-angle-left fa-2x" onClick={previous}></i>
        {renderYearSelector()}
        {renderMonthSelector()}
        <i className="fa fa-angle-right fa-2x" onClick={next}></i>
      </div>
      <DayNames dayNames={props.dayNames} />
      {renderWeeks()}
    </div>
  );
};

export default Calendar;
