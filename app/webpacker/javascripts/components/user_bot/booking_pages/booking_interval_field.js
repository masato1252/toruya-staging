"use strict"

import React from "react";

const BookingIntervalField = ({i18n, register}) => {
  return (
    <>
      <div className="field-row flex-start no-border">
        {i18n.interval_option}
        <select name="interval" ref={register({ required: true })}>
          <option value="10">10</option>
          <option value="15">15</option>
          <option value="30">30</option>
          <option value="60">60</option>
        </select>
        {i18n.per_minute}
      </div>
      <div className="field-row no-border">
        <div dangerouslySetInnerHTML={{ __html: i18n.interval_example_html }} />
      </div>
    </>
  )
}

export default BookingIntervalField;
