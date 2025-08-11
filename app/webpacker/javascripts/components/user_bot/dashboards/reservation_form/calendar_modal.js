"use strict";

import React from "react";
import Calendar from "shared/calendar/calendar";

const CalendarModal = ({i18n, calendar, dateSelectedCallback, selectedDate, props}) => {
  return (
    <div className="modal fade" id="calendar-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            {i18n.calendar}
          </div>
          <div className="modal-body scrollable">
            <Calendar
              {...calendar}
              dateSelectedCallback={dateSelectedCallback}
              schedulePath={Routes.personal_working_schedule_lines_user_bot_calendars_path({business_owner_id: props.business_owner_id, format: "json"})}
              selectedDate={selectedDate}
            />
          </div>
        </div>
      </div>
    </div>
  )
}

export default CalendarModal;
