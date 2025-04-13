"use strict"

import React from "react";
import { Controller } from "react-hook-form";
import moment from "moment-timezone";

import DatePickerField from "shared/date_picker_field"
import { TimePickerController } from "shared/components"

const BookingStartAtField = ({i18n, register, watch, control}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="start_at_type" type="radio" value="now" ref={register({ required: true })} />
        {i18n.sale_now}
      </label>
      <label className="field-row flex-start no-border">
        <input name="start_at_type" type="radio" value="date" ref={register({ required: true })} />
        {i18n.sale_on}
      </label>
      {watch("start_at_type") == "date" &&
        <div className="field-row flex-start">
          <Controller
            control={control}
            name="start_at_date_part"
            defaultValue={watch("start_at_date_part")}
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
            defaultValue={watch(`start_at_time_part`)}
            name={`start_at_time_part`}
          />
        </div>
      }
    </>
  )
}

export default BookingStartAtField;
