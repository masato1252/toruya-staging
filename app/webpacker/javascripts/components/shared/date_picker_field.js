"use strict";

import React from "react";
import moment from "moment-timezone";
import DayPickerInput from 'react-day-picker//DayPickerInput';
import MomentLocaleUtils, { parseDate } from 'react-day-picker/moment';
import _ from "lodash";

const MONTHS = {
  ja: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
};

const DatePickerField = ({date, handleChange, hiddenWeekDate, isDisabled}) => {
  moment.locale('ja');

  const formatMonthTitle = (d, locale = 'ja') => {
    return `${MONTHS[locale][d.getMonth()]} / ${d.getFullYear()}`;
  }

  return (
    <>
      <DayPickerInput
        onDayChange={handleChange}
        parseDate={parseDate}
        format={[ "YYYY/M/D", "YYYY-M-D" ]}
        dayPickerProps={{
          month: date && moment(date).toDate(),
          selectedDays: date && moment(date).toDate(),
          localeUtils: _.assign(MomentLocaleUtils, { formatMonthTitle }),
          locale: "ja"
        }}
        placeholder="yyyy/mm/dd"
        value={date && moment(date, [ "YYYY/M/D", "YYYY-M-D" ]).format("YYYY/M/D")}
        inputProps={{
          disabled: isDisabled
        }}
      />
      { date && !hiddenWeekDate ? <span>({moment(date).format("dd")})</span> : null }
    </>
  )
}

export default DatePickerField
