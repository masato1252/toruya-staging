"use strict";

import React from "react";
import { Field } from "react-final-form";

const handleSingleAttrInput = (component, event) => {
  const name = event.target.dataset.name;
  const value = event.target.value;

  component.setState({[name]: value});
};

const requiredValidation = (component, value) => (value ? undefined : component.props.i18n.errors.required);

const errorMessage = (error) => (
  <span className="field-error-message">{error}</span>
)
const InputRow = ({ label, type, input, requiredLabel, meta: { error, touched, submitFailed } }) => {
  const hasError = error && touched && submitFailed;

  return (
    <dl>
      <dt>{label} { requiredLabel && <strong>必須項目</strong> }</dt>
      <dd>
        <input {...input} type={type} placeholder={label} className={hasError ? "field-error" : ""} />
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
  <Field name={name} subscription={{ error: true, touched: true, submitFailed: true }}>
    {({ meta: { error, touched, submitFailed } }) =>
      error && touched && submitFailed ? errorMessage(error) : null
    }
  </Field>
);

export {
  handleSingleAttrInput,
  requiredValidation,
  InputRow,
  Radio,
  Error
};
