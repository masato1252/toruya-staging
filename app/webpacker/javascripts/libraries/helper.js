"use strict";

const composeValidators = (component, ...validators) => value =>
  validators.reduce((error, validator) => error || validator(component, value), undefined)

const requiredValidation = (key = "") => (component, value) => {
  if (component && (value === undefined || value === null || !String(value).length)) {
    return `${key}${component.props.i18n.errors.required}`
  }
  else {
    return undefined
  }
}

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

const greaterEqualThan = (number, key="") => (component, value) => {
  if (!value) return undefined;

  return value >= number ? undefined : `${key}${component.props.i18n.errors.greater_than_or_equal_to.replace(/%{value}/, number)}`
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
const isString = val => "string" === typeof val;

const setProperListHeight = (component, adjustHeight) => {
  const listHeight = `${$(window).innerHeight() - adjustHeight} px`;

  component.setState({listHeight: listHeight})

  $(window).resize(() => {
    component.setState({listHeight: listHeight})
  });
}

export {
  requiredValidation,
  emailFormatValidator,
  transformValues,
  composeValidators,
  lengthValidator,
  mustBeNumber,
  greaterEqualThan,
  setProperListHeight,
};
