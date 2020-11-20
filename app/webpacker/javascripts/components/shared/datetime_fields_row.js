"use strict"

import React from "react";
import DatePickerField from "shared/date_picker_field"
import moment from "moment-timezone";

const DateTimeFieldsRow = ({dateTimePeriod, setDateTimePeriod, ...rest}) => {
  const handleDateChange = (newDate) => {
    if (moment(newDate, [ "YYYY/M/D", "YYYY-M-D" ]).isValid()) {
      setDateTimePeriod((previousState) => (
        { ...previousState,
          start_at_date_part: moment(newDate).format("YYYY-MM-DD"),
          end_at_date_part: moment(newDate).format("YYYY-MM-DD"),
        }
      ));
    }
  }
  return (
    <div>
      <DatePickerField
        date={dateTimePeriod?.start_at_date_part || ""}
        handleChange={handleDateChange}
        hiddenWeekDate={true}
      />
      <input
        type="time"
        value={dateTimePeriod?.start_at_time_part || ""}
        onChange={(event) => setDateTimePeriod(previousState => ({ ...previousState, start_at_time_part: event.target.value }))} />
        {!rest.withoutEndTime &&
          <input
            type="time"
            value={dateTimePeriod?.end_at_time_part || ""}
            onChange={(event) => setDateTimePeriod(previousState => ({ ...previousState, end_at_time_part: event.target.value }))} />}
    </div>
  )
}

export default DateTimeFieldsRow;
