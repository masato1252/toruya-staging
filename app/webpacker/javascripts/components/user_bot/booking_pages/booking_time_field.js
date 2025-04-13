"use strict"

import React, { useState } from "react";
import { useFieldArray, Controller } from "react-hook-form";
import moment from "moment-timezone";

import I18n from 'i18n-js/index.js.erb';
import useDatetimeFieldsRow from "shared/use_datetime_fields_row"
import DatePickerField from "shared/date_picker_field"
import BookingIntervalField from "./booking_interval_field";
import { TimePickerController } from "shared/components";
const SpecificBookingTimeFields = ({specific_booking_time_fields, register, control, setValue}) => {
  return (
    specific_booking_time_fields.fields.map((field, index) => {
      return (
        <div key={field.id} className="field-row flex-start date-row no-border">
          <TimePickerController
            name={`booking_start_times[${index}].start_time`}
            control={control}
            defaultValue={field.start_time}
          />
          <button className="btn btn-orange" onClick={() => specific_booking_time_fields.remove(index)}>
            <i className="fa fa-minus"></i>
            <span>{I18n.t("action.delete")}</span>
          </button>
        </div>
      )
    }
    )
  )
}

const BookingTimeField = ({i18n, register, watch, control, setValue}) => {
  const specific_booking_time_fields = useFieldArray({
    control: control,
    name: "booking_start_times"
  });

  return (
    <div>
      <label className="field-row flex-start no-border">
        <input name="had_specific_booking_start_times" type="radio" value="false" ref={register({ required: true })} />
        {I18n.t('settings.booking_page.form.booking_time_interval_label')}
      </label>
      {watch("had_specific_booking_start_times") === "false" && <BookingIntervalField i18n={i18n} register={register} />}
      <div className="field-row no-content"></div>
      <label className="field-row flex-start no-border">
        <input name="had_specific_booking_start_times" type="radio" value="true" ref={register({ required: true })} />
        {I18n.t('settings.booking_page.form.specific_booking_start_times_label')}
      </label>
      {watch("had_specific_booking_start_times") === "true" && (
        <>
          <div className="field-row date-row flex-start no-border">
            <button className="btn btn-yellow" onClick={() => {
              specific_booking_time_fields.append({start_time: ""})
            }}>
              <i className="fa fa-plus"></i>
              <span>{I18n.t('settings.booking_page.form.add_booking_time_btn')}</span>
            </button>
          </div>
          <SpecificBookingTimeFields specific_booking_time_fields ={specific_booking_time_fields} control={control} register={register} setValue={setValue} i18n={i18n} />
          <div className="centerize margin-around" dangerouslySetInnerHTML={{ __html: I18n.t("settings.booking_page.form.specific_booking_start_times_desc_html") }} />
        </>
      )}
    </div>
  )
}

export default BookingTimeField;
