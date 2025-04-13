"use strict"

import React from "react";
import { Controller } from "react-hook-form";
import moment from "moment-timezone";

import DatePickerField from "shared/date_picker_field"
import { TimePickerController } from "shared/components"

const BookingEndAtField = ({i18n, register, watch, control}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="end_at_type" type="radio" value="never" ref={register({ required: true })} />
        {i18n.sale_forever}
      </label>
      <label className="field-row flex-start">
        <input name="end_at_type" type="radio" value="date" ref={register({ required: true })} />
        {i18n.sale_on}
      </label>
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
          <TimePickerController
            control={control}
            defaultValue={watch(`end_at_time_part`)}
            name={`end_at_time_part`}
          />
        </div>
      }
    </>
  )
}

export default BookingEndAtField;
