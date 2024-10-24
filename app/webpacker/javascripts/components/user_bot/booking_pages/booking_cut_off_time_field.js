"use strict"

import React from "react";
import { Controller } from "react-hook-form";
import moment from "moment-timezone";

import DatePickerField from "shared/date_picker_field"

const BookingCutOffTimeField = ({i18n, register, watch, control}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="cut_off_time_type" type="radio" value="never" ref={register({ required: true })} />
        {i18n.sale_forever}
      </label>
      <label className="field-row flex-start">
        <input name="cut_off_time_type" type="radio" value="date" ref={register({ required: true })} />
        {i18n.sale_on}
      </label>
      {watch("cut_off_time_type") == "date" &&
        <div className="field-row flex-start">
          <Controller
            control={control}
            name="cut_off_time_date_part"
            defaultValue={watch("cut_off_time_date_part")}
            render={({ onChange, value }) => (
              <DatePickerField
                date={value && moment(value, [ "YYYY/M/D", "YYYY-M-D" ]).format("YYYY/M/D")}
                handleChange={newDate => {
                  onChange(moment(newDate).format("YYYY-MM-DD"))
                }}
              />
            )}
          />
          <input type="time" name={`cut_off_time_time_part`} ref={register} />
        </div>
      }
    </>
  )
}

export default BookingCutOffTimeField;
