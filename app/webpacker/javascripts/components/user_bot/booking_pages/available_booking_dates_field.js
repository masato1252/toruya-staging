"use strict"

import React from "react";
import { useFieldArray, Controller } from "react-hook-form";
import moment from "moment-timezone";

import useDatetimeFieldsRow from "shared/use_datetime_fields_row"
import DatePickerField from "shared/date_picker_field"

const SpecialDatesFields = ({special_dates_fields, register, control, setValue}) => {
  return (
    special_dates_fields.fields.map((field, index) => (
      <div key={field.id} className="field-row flex-start">
        <Controller
          control={control}
          name={`special_dates[${index}].start_at_date_part`}
          defaultValue={field.start_at_date_part}
          render={({ onChange, value }) => (
            <DatePickerField
              date={value && moment(value, [ "YYYY/M/D", "YYYY-M-D" ]).format("YYYY/M/D")}
              handleChange={newDate => {
                const newDateValue = moment(newDate).format("YYYY-MM-DD")
                onChange(newDateValue)
                setValue(`special_dates[${index}].end_at_date_part`, newDateValue)
              }}
            />
          )}
        />
        <input type="hidden" name={`special_dates[${index}].end_at_date_part`} ref={register({ required: true })} defaultValue={field.end_at_time_part} />
        <input type="time" name={`special_dates[${index}].start_at_time_part`} ref={register({ required: true })} defaultValue={field.start_at_time_part} />
        <input type="time" name={`special_dates[${index}].end_at_time_part`} ref={register({ required: true })} defaultValue={field.end_at_time_part} />
        <button className="btn btn-orange" onClick={() => special_dates_fields.remove(index)}>
          <i className="fa fa-minus"></i>
        </button>
      </div>
    ))
  )
}

const AvailableBookingDatesField = ({i18n, register, watch, control, setValue}) => {
  const [newSpecialDatePeriod, DateTimeFieldsRow] = useDatetimeFieldsRow({})

  const special_dates_fields = useFieldArray({
    control: control,
    name: "special_dates"
  });

  return (
    <div>
      <div className="field-row">
        <label>
          <input name="had_special_date" type="radio" value="false" ref={register({ required: true })} />
          {i18n.default_available_dates_label}
        </label>
      </div>
      <div className="field-row">
        <label>
          <input name="had_special_date" type="radio" value="true" ref={register({ required: true })} />
          {i18n.special_date_label}
        </label>
      </div>
      {watch("had_special_date") == "true" &&
        <>
          <SpecialDatesFields special_dates_fields={special_dates_fields} control={control} register={register} setValue={setValue} />
          <div className="field-row">
            {DateTimeFieldsRow}
            <button className="btn btn-yellow" onClick={() => {
              if (
                newSpecialDatePeriod.start_at_date_part &&
                newSpecialDatePeriod.start_at_time_part &&
                newSpecialDatePeriod.end_at_date_part &&
                newSpecialDatePeriod.end_at_time_part
              ) {
                special_dates_fields.append(newSpecialDatePeriod)
              }
            }}>
              <i className="fa fa-plus"></i>
            </button>
          </div>
        </>
      }
    </div>
  )
}

export default AvailableBookingDatesField;
