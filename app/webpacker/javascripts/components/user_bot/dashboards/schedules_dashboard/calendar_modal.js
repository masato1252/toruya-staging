"use strict";

import React from "react";
import Calendar from "shared/calendar/calendar";

const CalendarModal = ({props}) => {
  return (
    <div className="modal fade" id="calendar-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            {props.i18n.calendar}
          </div>
          <div className="modal-body">
            <Calendar
              {...props.calendar}
              dateSelectedCallbackPath={Routes.lines_user_bot_schedules_path()}
              schedulePath={Routes.personal_working_schedule_lines_user_bot_calendars_path({format: "json"})}
              selectedDate={props.params.reservation_date}
            />
          </div>
        </div>
      </div>
    </div>

  )
}

export default CalendarModal;
