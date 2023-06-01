"use strict"

import React from "react";
import { useFieldArray, Controller } from "react-hook-form";
import moment from "moment-timezone";

import DatePickerField from "shared/date_picker_field"
import I18n from 'i18n-js/index.js.erb';

const SpecialDatesFields = ({special_dates_fields, register, control, setValue, i18n}) => {
  return (
    special_dates_fields.fields.map((field, index) => (
      <div key={field.id} className="field-row flex-start date-row">
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
        <input type="date" name={`special_dates[${index}].end_at_date_part`} ref={register({ required: true })} defaultValue={field.end_at_date_part} className="display-hidden"/>
        <input type="time" name={`special_dates[${index}].start_at_time_part`} ref={register({ required: true })} defaultValue={field.start_at_time_part} />
        <input type="time" name={`special_dates[${index}].end_at_time_part`} ref={register({ required: true })} defaultValue={field.end_at_time_part} />
        <button className="btn btn-orange" onClick={() => special_dates_fields.remove(index)}>
          <i className="fa fa-minus"></i>
          <span>{i18n.delete}</span>
        </button>
      </div>
    ))
  )
}

const AvailableBookingDatesField = ({i18n, register, watch, control, setValue}) => {
  const special_dates_fields = useFieldArray({
    control: control,
    name: "special_dates"
  });

  return (
    <div>
      <label className="field-row flex-start">
        <input name="booking_type" type="radio" value="any" ref={register({ required: true })} />
        {i18n.any_label}
      </label>
      <label className="field-row flex-start">
        <input name="booking_type" type="radio" value="only_special_dates_booking" ref={register({ required: true })} />
        {i18n.only_special_dates_booking_label}
      </label>
      {_.includes(["only_special_dates_booking"], watch("booking_type")) &&
        <>
          <div className="field-row date-row flex-start">
            <button className="btn btn-yellow" onClick={() => {
              special_dates_fields.append({})
            }}>
              <i className="fa fa-plus"></i>
              <span>{I18n.t('settings.booking_page.form.add_special_dates_btn')}</span>
            </button>
          </div>
          <SpecialDatesFields special_dates_fields={special_dates_fields} control={control} register={register} setValue={setValue} i18n={i18n} />
        </>
      }
      <label className="field-row flex-start no-border">
        <input name="booking_type" type="radio" value="event_booking" ref={register({ required: true })} />
        {i18n.event_booking_label}
      </label>
      {_.includes(["event_booking"], watch("booking_type")) &&
        <>
          <div className="field-row date-row flex-start">
            <button className="btn btn-yellow" onClick={() => {
              special_dates_fields.append({})
            }}>
              <i className="fa fa-plus"></i>
              <span>{I18n.t('settings.booking_page.form.add_special_dates_btn')}</span>
            </button>
          </div>
          <SpecialDatesFields special_dates_fields={special_dates_fields} control={control} register={register} setValue={setValue} i18n={i18n} />
          <div>{I18n.t("settings.booking_page.form.event_booking_hint")}</div>
        </>
      }
    </div>
  )
}

export default AvailableBookingDatesField;
