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

const DatetimeField = ({collection_name, fields, results, timezone}) => (
  <div className="select-multiple-inputs">
    {results(fields, collection_name, timezone)}
    <Field
      name="start_at_date_part"
      component={DateFieldAdapter}
      date={moment.tz(timezone).format("YYYY-MM-DD")}
      hiddenWeekDate={true}
    />
    <Field
      name="start_at_time_part"
      type="time"
      component="input"
    />
    ～
    <Field
      name="end_at_date_part"
      type="hidden"
      component="input"
    />
    <Field
      name="end_at_time_part"
      type="time"
      component="input"
    />
    <FormSpy subscription={{ values: true }}>
      {({ values }) => (
        <a
          href="#"
          className={`btn btn-symbol btn-yellow after-field-btn ${!values.start_at_time_part || !values.end_at_time_part ? "disabled" : ""}`}
          onClick={(event) => {
            event.preventDefault();

            const start_at_date_part = values.start_at_date_part || moment.tz(timezone).format("YYYY-MM-DD");

            fields.push({
              start_at_date_part: start_at_date_part,
              start_at_time_part: values.start_at_time_part,
              end_at_date_part: start_at_date_part,
              end_at_time_part: values.end_at_time_part
            })
          }}>
          <i className="fa fa-plus" aria-hidden="true" ></i>
        </a>
      )}
    </FormSpy>
  </div>
)

const MultipleDatetimeInput = ({collection_name, resultFields, timezone}) => {
  const results = resultFields || defaultResultFields

  return (
    <FieldArray name={collection_name} component={DatetimeField} results={results} timezone={ timezone || "Asia/Tokyo" }/>
  );
}

export default MultipleDatetimeInput;
