"use strict"

import React from "react";

const BookingLimitDayField = ({i18n, register}) => {
  return (
    <>
      <div className="field-row flex-start">
        <select name="booking_limit_day" ref={register({ required: true })}>
          <option value="0">0</option>
          <option value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
          <option value="5">5</option>
          <option value="6">6</option>
          <option value="7">7</option>
        </select>
        {i18n.booking_limit_day_before}
      </div>
      <div className="field-row">
        <div dangerouslySetInnerHTML={{ __html: i18n.booking_limit_day_example_html }} />
      </div>
    </>
  )
}

export default BookingLimitDayField;
