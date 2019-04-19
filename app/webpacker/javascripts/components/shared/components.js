import React from "react";
import { Field } from "react-final-form";

const errorMessage = (error) => (
  <p className="field-error-message">{error}</p>
)

const InputRow = ({ label, type, input, requiredLabel, hint, before_hint, meta: { error, touched } }) => {
  const hasError = error && touched;

  return (
    <dl>
      <dt>{label} { requiredLabel ? <strong>{requiredLabel}</strong> : ""}</dt>
      <dd>
        { before_hint ? <span className="before-field-hint">{before_hint}</span> : ""}
        <input {...input} type={type} placeholder={label} className={hasError ? "field-error" : ""} />
        { hint ? <span className="field-hint">{hint}</span> : ""}
        { hasError && errorMessage(error) }
      </dd>
    </dl>
  );
}

const Radio = ({ input, children }) =>
  // input should contain checked value to indicate
  // if the input is checked
  (
    <label>
      <input type="radio" {...input} />
      {children}
    </label>
  );

const Error = ({ name }) => (
  <Field name={name} subscription={{ error: true, touched: true }}>
    {({ meta: { error, touched } }) =>
      error && touched ? errorMessage(error) : null
    }
  </Field>
);

const Condition = ({ when, is, children }) => (
  <Field name={when} subscription={{ value: true }}>
    {({ input: { value } }) => (value === is ? children : null)}
  </Field>
);

export {
  InputRow,
  Radio,
  Error,
  Condition
};
