"use strict";

const requiredValidation = (component, value) => (value ? undefined : component.props.i18n.errors.required);

const transformValues = values => {
  const data = {...values};

  // Move object boolean true/false value to string "true" or "false"
  Object.keys(data).forEach((key) => {
    if (isBoolean(data[key])) {
      data[key] = data[key] ? "true" : "false"
    }
  })

  return data;
};

const isBoolean = val => "boolean" === typeof val;

export {
  requiredValidation,
  transformValues
};
