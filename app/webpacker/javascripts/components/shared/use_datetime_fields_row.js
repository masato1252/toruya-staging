"use strict"

import React, { useState } from "react";
import DateTimeFieldsRow from "shared/datetime_fields_row";

const useDatetimeFieldsRow = ({...props}) => {
  const [dateTimePeriod, setDateTimePeriod] = useState({})

  return (
    [
      dateTimePeriod,
      <DateTimeFieldsRow
        dateTimePeriod={dateTimePeriod}
        setDateTimePeriod={setDateTimePeriod}
        {...props}
      />
    ]
  )
}

export default useDatetimeFieldsRow;
