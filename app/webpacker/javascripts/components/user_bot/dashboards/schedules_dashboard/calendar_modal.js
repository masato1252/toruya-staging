"use strict";

import React, { useState } from "react";
import Calendar from "shared/calendar/calendar";
import I18n from 'i18n-js/index.js.erb';

const CalendarModal = ({props}) => {
  const [month_date, setMonthDate] = useState()
  const calendarChangedCallback = ({month, ...rest}) => {
    setMonthDate(month.format("YYYY-MM-DD"))
  }

  return (
    <div className="modal fade" id="calendar-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            {props.i18n.calendar}
          </div>
          <div className="modal-body scrollable">
            <Calendar
              {...props.calendar}
              dateSelectedCallbackPath={props.my_calendar ? Routes.mine_lines_user_bot_schedules_path() : Routes.lines_user_bot_schedules_path({ business_owner_id: props.business_owner_id })}
              schedulePath={props.my_calendar ? Routes.my_working_schedule_lines_user_bot_calendars_path({format: "json"}) : Routes.personal_working_schedule_lines_user_bot_calendars_path({business_owner_id: props.business_owner_id, format: "json"})}
              selectedDate={props.params.reservation_date || props.params.month_date}
              calendarChangedCallback={calendarChangedCallback}
            />
          </div>

          <div className="margin-around centerize">
            <a
              className="btn btn-gray"
              href={props.my_calendar ? Routes.mine_lines_user_bot_schedules_path({ business_owner_id: props.business_owner_id, month_date: month_date }) : Routes.lines_user_bot_schedules_path({ business_owner_id: props.business_owner_id, month_date: month_date })}>
              {I18n.t("user_bot.dashboards.schedules.whole_month_schedule")}
            </a>
          </div>
        </div>
      </div>
    </div>

  )
}

export default CalendarModal;
