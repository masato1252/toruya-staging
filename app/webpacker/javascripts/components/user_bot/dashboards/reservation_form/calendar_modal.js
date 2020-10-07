"use strict";

import React from "react";
import Calendar from "shared/calendar/calendar";

const CalendarModal = ({calendar, dateSelectedCallback, selectedDate}) => {
  return (
    <div className="modal fade" id="calendar-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            Calendar
          </div>
          <div className="modal-body">
            <Calendar
              {...calendar}
              dateSelectedCallback={dateSelectedCallback}
              schedulePath={Routes.personal_working_schedule_lines_user_bot_calendars_path({format: "json"})}
              selectedDate={selectedDate}
            />
          </div>
        </div>
      </div>
    </div>
  )
}

export default CalendarModal;
