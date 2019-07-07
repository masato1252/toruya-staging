"use strict";

const composeValidators = (component, ...validators) => value =>
  validators.reduce((error, validator) => error || validator(component, value), undefined)

const requiredValidation = (component, value, key = "") => (value ? undefined : `${key}${component.props.i18n.errors.required}`);

const emailPatten =  /^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w{2,}([-.]\w+)*$/u;
const emailFormatValidator = (component, value) => {
  if (!value) return undefined;

  return emailPatten.test(value) ? undefined : component.props.i18n.errors.invalid_email_format
}

const mustBeNumber = (component, value) => (isNaN(value) ? component.props.i18n.errors.not_a_number : undefined)

const lengthValidator = required_length => (component, value) => {
  if (!value) return undefined;

  return value.length === required_length ? undefined : component.props.i18n.errors.wrong_length.replace(/%{count}/, required_length)
}

const transformValues = values => {
  const data = {...values};

  // Move object boolean true/false value to string "true" or "false"
  Object.keys(data).forEach((key) => {
    if (isBoolean(data[key])) {
      data[key] = data[key] ? "true" : "false"
    }

    if (isNumber(data[key])) {
      data[key] = `${data[key]}`
    }
  })

  return data;
};

const isBoolean = val => "boolean" === typeof val;
const isNumber = val => "number" === typeof val;

export {
  requiredValidation,
  emailFormatValidator,
  transformValues,
  composeValidators,
  lengthValidator,
  mustBeNumber
};
