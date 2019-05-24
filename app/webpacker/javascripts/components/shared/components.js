import React from "react";
import { Field } from "react-final-form";
import _ from "lodash";

const errorMessage = (error) => (
  <p className="field-error-message">{error}</p>
)

const Input = ({input, meta, ...rest}) => {
  const { error, touched } = meta;

  return (
    <input {...input} {...rest} className={error && touched ? "field-error" : ""} />
  )
}

const InputRow = ({ label, placeholder, type, input, requiredLabel, hint, before_hint, componentType, meta: { error, touched }, ...rest }) => {
  const hasError = error && touched;
  const Component = componentType || "input";

  return (
    <dl>
      {label ?
        <dt>
          {label} { requiredLabel ? <strong>{requiredLabel}</strong> : "" }
        </dt> : ""
      }
      <dd>
        { before_hint ? <span className="before-field-hint">{before_hint}</span> : ""}
        <Component {...input} {...rest} type={type} placeholder={placeholder || label} className={hasError ? "field-error" : ""} />
        { hint ? <span className="field-hint">{hint}</span> : ""}
        { hasError && errorMessage(error) }
      </dd>
    </dl>
  );
}

const RadioRow = ({ input, children }) =>
  (
    <dl>
      <dd>
        <div className="radio">
          <Radio input={input}>
            {children}
          </Radio>
        </div>
      </dd>
    </dl>
  );

const Radio = ({ input, children }) =>
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
    {({ input: { value } }) =>
      {
        if (is === "present") {
          const isPresent = Array.isArray(value) ? value.length : !!value;

          return isPresent ? children : null
        }
        else if (is === "blank") {
          const isPresent = Array.isArray(value) ? value.length : !!value;

          return isPresent ? null : children
        }
        else if (Array.isArray(is)) {
          return _.isEqual(_.sortBy(value), _.sortBy(is)) ? children : null
        }
        else if (typeof value === "boolean")
          return String(value) === is ? children : null
        else {
          return value === is ? children : null
        }
      }
    }
  </Field>
);

export {
  Input,
  InputRow,
  RadioRow,
  Radio,
  Error,
  Condition
};
