"use strict";

import React from "react";
import moment from "moment-timezone";
import DayPickerInput from 'react-day-picker//DayPickerInput';
import MomentLocaleUtils, { parseDate } from 'react-day-picker/moment';
import _ from "lodash";
import { getMomentLocale } from "libraries/helper.js";

const MONTHS = {
  ja: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  'zh-TW': ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
};

const DatePickerField = ({date, handleChange, hiddenWeekDate, isDisabled, locale = 'ja'}) => {
  const momentLocale = getMomentLocale(locale);
  moment.locale(momentLocale);

  const formatMonthTitle = (d, displayLocale = momentLocale) => {
    // Use 'ja' as fallback for MONTHS if the locale isn't defined in our mapping
    const monthsLocale = MONTHS[displayLocale] ? displayLocale : 'ja';
    return `${MONTHS[monthsLocale][d.getMonth()]} / ${d.getFullYear()}`;
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
          locale: momentLocale
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
