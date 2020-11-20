"use strict"

import React from "react";
import { Controller } from "react-hook-form";
import moment from "moment-timezone";

import DatePickerField from "shared/date_picker_field"

const BookingEndAtField = ({i18n, register, watch, control}) => {
  return (
    <>
      <div className="field-row">
        <label>
          <input name="end_at_type" type="radio" value="now" ref={register({ required: true })} />
          {i18n.sale_forever}
        </label>
      </div>
      <div className="field-row">
        <label>
          <input name="end_at_type" type="radio" value="date" ref={register({ required: true })} />
          {i18n.sale_on}
        </label>
      </div>
      {watch("end_at_type") == "date" &&
        <div className="field-row flex-start">
          <Controller
            control={control}
            name="end_at_date_part"
            defaultValue={watch("end_at_date_part")}
            render={({ onChange, value }) => (
              <DatePickerField
                date={value && moment(value, [ "YYYY/M/D", "YYYY-M-D" ]).format("YYYY/M/D")}
                handleChange={newDate => {
                  onChange(moment(newDate).format("YYYY-MM-DD"))
                }}
              />
            )}
          />
          <input type="time" name={`end_at_time_part`} ref={register} />
        </div>
      }
    </>
  )
}

export default BookingEndAtField;
