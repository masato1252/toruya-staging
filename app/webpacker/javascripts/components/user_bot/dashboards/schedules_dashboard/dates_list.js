"use strict";

import React, { useState, useEffect, useMemo } from "react";
import moment from "moment-timezone";
import useSchedules from "libraries/use_schedules";
import { isWorkingDate, isHoliday, isReservedDate, isAvailableBookingDate, isPersonalScheduleDate } from "libraries/helper";
import mergeArrayOfObjects from "libraries/merge_array_of_objects";
import _ from "lodash";

const DatesList = ({props}) => {
  moment.locale(props.locale);

  const period = props.is_not_phone ? 7 : 3;
  const [startDate, setStartDate] = useState(moment(props.startDate))
  const [endDate, setEndDate] = useState(moment(props.startDate).add(period, "day"))
  const schedules1 = useSchedules({ business_owner_id: props.business_owner_id, date: startDate });
  const schedules2 = useSchedules({ business_owner_id: props.business_owner_id, date: endDate});

  const renderDatesList = () => {
    let list = [startDate]
    let schedules = mergeArrayOfObjects(schedules1, schedules2)

    for (var i = 1; i < period; i++) {
      list.push(startDate.clone().add(i, "day"))
    }

    return list.map((day) => {
      return (
        <a
          className={
            "date" + (day.isSame(new Date(), "day") ? " today" : "") +
              (day.isSame(props.selectedDate) ? " selected" : "") +
              (isHoliday(schedules, day) ? " holiday" : "") +
              (isWorkingDate(schedules, day) ? " work-day" : "") +
              (isReservedDate(schedules, day) ? " reserved" : "") +
              (isAvailableBookingDate(schedules, day) ? " booking-available" : "") +
              (isPersonalScheduleDate(schedules, day) ? " personal-schedule" : "")
          }
          key={day}
          href={props.my_calendar ? Routes.my_date_lines_user_bot_schedules_path(day.format("YYYY-MM-DD"), { schedule_display_start_date: startDate.format("YYYY-MM-DD") }) : Routes.date_lines_user_bot_schedules_path(props.business_owner_id, day.format("YYYY-MM-DD"), { schedule_display_start_date: startDate.format("YYYY-MM-DD") })}
        >
          <div>
            <b>{day.format("MM/DD")}</b>
          </div>
          <div>
            {props.calendar.dayNames[day.day()]}
          </div>
        </a>
      )
    })
  }

  const onPrevDates = () => {
    setStartDate(startDate.clone().add(-1, "day"));
    setEndDate(endDate.clone().add(-1, "day"));
  }

  const onNextDates = () => {
    setStartDate(startDate.clone().add(1, "day"));
    setEndDate(endDate.clone().add(1, "day"));
  }

  return (
    <div className="dates-list">
      <div className="prev-dates" onClick={onPrevDates}><i className="fa fa-angle-left"></i></div>
      {renderDatesList()}
      <div className="next-dates" onClick={onNextDates}><i className="fa fa-angle-right"></i></div>
    </div>
  )
}

export default DatesList;
