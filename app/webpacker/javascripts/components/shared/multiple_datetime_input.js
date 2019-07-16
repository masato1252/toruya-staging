import React from "react";
import { Field, FormSpy } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import moment from "moment-timezone";

import DateFieldAdapter from "./date_field_adapter";

const defaultResultFields = (fields, collection_name, timezone) => {
  return (
    <div className="result-fields">
      {fields.map((field, index) => {
        return (
         <div key={`${collection_name}-${index}`} className="result-field">
            <Field
              name={`${field}start_at_date_part`}
              component={DateFieldAdapter}
              date={moment.tz(timezone).format("YYYY-MM-DD")}
              hiddenWeekDate={true}
            />
            <Field
              name={`${field}start_at_time_part`}
              type="time"
              component="input"
            />
             ～
            <Field
              name={`${field}end_at_date_part`}
              type="hidden"
              component="input"
            />
            <Field
              name={`${field}end_at_time_part`}
              type="time"
              component="input"
            />
           <a
             href="#"
             className="btn btn-symbol btn-orange after-field-btn"
             onClick={(event) => {
                 event.preventDefault();
                 fields.remove(index)
               }
             }>
             <i className="fa fa-minus" aria-hidden="true" ></i>
           </a>
         </div>
        )
       })}
    </div>
  );
};

const DatetimeField = ({ input_prefix_name, collection_name, fields, results, timezone, dateChangedCallback, state_form, i18n }) => (
  <div className="select-multiple-inputs">
    {results(fields, collection_name, timezone)}
    <Field
      name={`${input_prefix_name}_start_at_date_part_input`}
      component={DateFieldAdapter}
      date={moment.tz(timezone).format("YYYY-MM-DD")}
      dateChangedCallback={dateChangedCallback}
      hiddenWeekDate={true}
    />
    <Field
      name={`${input_prefix_name}_start_at_time_part_input`}
      type="time"
      component="input"
    />
    ～
    <Field
      name={`${input_prefix_name}_end_at_date_part_input`}
      type="hidden"
      component="input"
    />
    <Field
      name={`${input_prefix_name}_end_at_time_part_input`}
      type="time"
      component="input"
    />
    <FormSpy subscription={{ values: true }}>
      {({ values }) => {
        // XXX: Because we only show the end time field in the view, so when start date changed,
        // the end date should always the same as star date

        values.booking_page.special_dates.forEach((special_date, i) => {
          if (special_date.start_at_date_part != special_date.end_at_date_part) {
            fields.update(i, {
              start_at_date_part: special_date.start_at_date_part,
              start_at_time_part: special_date.start_at_time_part,
              end_at_date_part: special_date.start_at_date_part,
              end_at_time_part: special_date.end_at_time_part
            })
          }
        })

        return null;
      }}
    </FormSpy>
    <FormSpy subscription={{ values: true }}>
      {({ values }) => (
        <a
          href="#"
          className={`btn btn-yellow after-field-btn ${!values[`${input_prefix_name}_start_at_time_part_input`] || !values[`${input_prefix_name}_end_at_time_part_input`] ? "disabled" : ""}`}
          onClick={(event) => {
            event.preventDefault();
            const start_date_input_name = `${input_prefix_name}_start_at_date_part_input`
            const start_time_input_name = `${input_prefix_name}_start_at_time_part_input`
            const end_date_input_name = `${input_prefix_name}_end_at_date_part_input`
            const end_time_input_name = `${input_prefix_name}_end_at_time_part_input`

            const start_at_date_part = values[start_date_input_name] || moment.tz(timezone).format("YYYY-MM-DD");

            fields.push({
              start_at_date_part: start_at_date_part,
              start_at_time_part: values[start_time_input_name],
              end_at_date_part: start_at_date_part,
              end_at_time_part: values[end_time_input_name]
            })

            state_form.change(start_date_input_name, null)
            state_form.change(start_time_input_name, null)
            state_form.change(end_date_input_name, null)
            state_form.change(end_time_input_name, null)
          }}>
            {i18n.save}
        </a>
      )}
    </FormSpy>
  </div>
)

const MultipleDatetimeInput = ({collection_name, resultFields, timezone, dateChangedCallback, input, state_form, i18n}) => {
  const results = resultFields || defaultResultFields

  return (
    <FieldArray
      input_prefix_name={input.name}
      name={collection_name}
      component={DatetimeField}
      results={results}
      timezone={ timezone || "Asia/Tokyo" }
      dateChangedCallback={dateChangedCallback}
      state_form={state_form}
      i18n={i18n}
    />
  );
}

export default MultipleDatetimeInput;
