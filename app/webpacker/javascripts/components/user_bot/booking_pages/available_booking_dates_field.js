"use strict"

import React, { Fragment } from "react";
import { useFieldArray, Controller } from "react-hook-form";
import moment from "moment-timezone";
import DatePickerField from "shared/date_picker_field"
import { TimePickerController } from "shared/components"
import I18n from 'i18n-js/index.js.erb';
import { generateNextSpecialDate } from "libraries/helper"

const SpecialDatesFields = ({special_dates_fields, register, control, watch, setValue, i18n}) => {
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
        <TimePickerController
          name={`special_dates[${index}].start_at_time_part`}
          control={control}
          defaultValue={watch(`special_dates[${index}].start_at_time_part`)}
        /> ～
        <TimePickerController
          name={`special_dates[${index}].end_at_time_part`}
          control={control}
          defaultValue={watch(`special_dates[${index}].end_at_time_part`)}
        />
        <button className="btn btn-orange" onClick={() => special_dates_fields.remove(index)}>
          <i className="fa fa-minus"></i>
          <span>{i18n.delete}</span>
        </button>
      </div>
    ))
  )
}

const WeekdayBusinessSchedules = ({register, weekday, business_schedule_fields, control, watch}) => {
  const weekday_business_schedule_fields = business_schedule_fields.fields

  return (
    <>
      <div className="p-3">{I18n.t("date.day_names")[weekday]}</div>
      {weekday_business_schedule_fields.map((field, index) => {
        if (field.day_of_week != weekday) return <Fragment key={field.id}></Fragment>

        return (
          <div key={field.id} className="field-row flex-start">
            <input type="hidden" name={`business_schedules[${index}].day_of_week`} defaultValue={field.day_of_week} ref={register({ required: true })} />
            <TimePickerController
              name={`business_schedules[${index}].start_time`}
              control={control}
              defaultValue={watch(`business_schedules[${index}].start_time`)}
            />
            〜
            <TimePickerController
              name={`business_schedules[${index}].end_time`}
              control={control}
              defaultValue={watch(`business_schedules[${index}].end_time`)}
            />
            {weekday_business_schedule_fields.filter((field) => field.day_of_week == weekday).length > 0 && (
              <button className="btn btn-orange" onClick={() => business_schedule_fields.remove(index)}>
                <i className="fa fa-minus"></i>
                <span>{I18n.t("action.delete")}</span>
              </button>
            )}
          </div>
        )
      })}
      <div className="field-row flex-start">
        <button className="btn btn-yellow" onClick={() => {
          business_schedule_fields.append({
            day_of_week: weekday,
            start_time: "09:00",
            end_time: "17:00"
          })
        }}>
          <i className="fa fa-plus"></i>
          <span>{I18n.t('settings.booking_page.form.business_schedules_booking_add_button')}</span>
        </button>
      </div>
    </>
  )
}

const AvailableBookingDatesField = ({i18n, register, watch, control, setValue}) => {
  const special_dates_fields = useFieldArray({
    control: control,
    name: "special_dates"
  });

  const business_schedule_fields = useFieldArray({
    control: control,
    name: "business_schedules"
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
              const nextSpecialDate = generateNextSpecialDate(special_dates_fields.fields);
              special_dates_fields.append(nextSpecialDate);
            }}>
              <i className="fa fa-plus"></i>
              <span>{I18n.t('settings.booking_page.form.add_special_dates_btn')}</span>
            </button>
          </div>
          <SpecialDatesFields special_dates_fields={special_dates_fields} control={control} register={register} watch={watch} setValue={setValue} i18n={i18n} />
        </>
      }
      <label className="field-row flex-start">
        <input name="booking_type" type="radio" value="business_schedules_booking" ref={register({ required: true })} />
        {i18n.business_schedules_booking_label}
      </label>
      {_.includes(["business_schedules_booking"], watch("booking_type")) &&
      <>
        {[1, 2, 3, 4, 5, 6, 0].map((weekday) => {
          return (
            <WeekdayBusinessSchedules
              key={weekday}
              register={register}
              weekday={weekday}
              business_schedule_fields={business_schedule_fields}
              control={control}
              watch={watch}
            />
          )
        })}
      </>}
      <label className="field-row flex-start">
        <input name="booking_type" type="radio" value="event_booking" ref={register({ required: true })} />
        {i18n.event_booking_label}
      </label>
      {_.includes(["event_booking"], watch("booking_type")) &&
        <>
          <div className="field-row date-row flex-start">
            <button className="btn btn-yellow" onClick={() => {
              const nextSpecialDate = generateNextSpecialDate(special_dates_fields.fields);
              special_dates_fields.append(nextSpecialDate);
            }}>
              <i className="fa fa-plus"></i>
              <span>{I18n.t('settings.booking_page.form.add_special_dates_btn')}</span>
            </button>
          </div>
          <SpecialDatesFields special_dates_fields={special_dates_fields} control={control} register={register} watch={watch} setValue={setValue} i18n={i18n} />
          <div>{I18n.t("settings.booking_page.form.event_booking_hint")}</div>
        </>
      }
    </div>
  )
}

export default AvailableBookingDatesField;
