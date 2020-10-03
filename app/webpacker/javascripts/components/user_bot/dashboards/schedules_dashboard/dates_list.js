"use strict";

import React, { useState, useEffect, useMemo } from "react";
import moment from "moment-timezone";
import { UsersServices } from "user_bot/api";
import useSchedules from "libraries/use_schedules";
import { isWorkingDate, isHoliday, isReservedDate, isAvailableBookingDate } from "libraries/helper";
import _ from "lodash";

const DatesList = ({props}) => {
  moment.locale('ja');

  const period = 4;
  const [startDate, setStartDate] = useState(moment(props.date))
  const [endDate, setEndDate] = useState(moment(props.date).add(period, "day"))
  const schedules1 = useSchedules(startDate);
  const schedules2 = useSchedules(endDate);

  const renderDatesList = () => {
    let list = [startDate]

    for (var i = 1; i < period; i++) {
      list.push(startDate.clone().add(i, "day"))
    }

    return list.map((day) => {
      return (
        <a
          className={
            "date" + (day.isSame(new Date(), "day") ? " today" : "") +
              (day.isSame(props.date) ? " selected" : "") +
              (isHoliday(schedules, day) ? " holiday" : "") +
              (isWorkingDate(schedules, day) ? " work-day" : "") +
              (isReservedDate(schedules, day) ? " reserved" : "") +
              (isAvailableBookingDate(schedules, day) ? " booking-available" : "")
          }
          key={day}
          href={Routes.date_lines_user_bot_schedules_path(day.format("YYYY-MM-DD"))}
        >
          <div>
            <b>{day.format("MM/DD")}</b>
          </div>
          <div>
            {day.format("dd")}
          </div>
        </a>
      )
    })
  }

  const onPrevDates = () => {
    setStartDate(startDate.clone().add(-period, "day"));
    setEndDate(endDate.clone().add(-period, "day"));
  }

  const onNextDates = () => {
    setStartDate(startDate.clone().add(period, "day"));
    setEndDate(endDate.clone().add(period, "day"));
  }

  const schedules = useMemo(() => {
    return _.merge({}, schedules1, schedules2)
  },
    [schedules1, schedules2]
  )
  return (
    <div className="dates-list">
      <div className="prev-dates" onClick={onPrevDates}><i className="fa fa-angle-left"></i></div>
      {renderDatesList()}
      <div className="next-dates" onClick={onNextDates}><i className="fa fa-angle-right"></i></div>
    </div>
  )
}

export default DatesList;
