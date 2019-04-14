"use strict";

import React from "react";

const handleSingleAttrInput = (component, event) => {
  const name = event.target.dataset.name;
  const value = event.target.value;

  component.setState({[name]: value});
};

const requiredValidation = (component, value) => (value ? undefined : component.props.i18n.errors.required);

const InputRow = ({ label, type, input, requiredLabel, meta: { error, touched, submitFailed } }) => {
  const hasError = error && touched && submitFailed;

  return (
    <dl>
      <dt>{label} { requiredLabel && <strong>必須項目</strong> }</dt>
      <dd>
        <input {...input} type={type} placeholder={label} className={hasError ? "field-error" : ""} />
        { hasError && <span className="field-error-message">{error}</span> }
      </dd>
    </dl>
  );
}

export {
  handleSingleAttrInput,
  requiredValidation,
  InputRow
};
