import React from "react";
import { Field } from "react-final-form";
import _ from "lodash";
import { sortableHandle } from "react-sortable-hoc";

const errorMessage = (error) => (
  <p className="field-error-message">{error}</p>
)

const Input = ({input, meta, ...rest}) => {
  const { error, touched } = meta;

  return (
    <input {...input} {...rest} className={error && touched ? "field-error" : ""} />
  )
}

const InputRow = ({ label, placeholder, type, input, requiredLabel, hint, before_hint, componentType, touched_required = true, meta: { error, touched }, ...rest }) => {
  const hasError = error && (touched_required ? touched : true);
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

const Error = ({ name, touched_required = true }) => (
  <Field name={name} subscription={{ error: true, touched: touched_required }}>
    {({ meta: { error, touched } }) =>
      error && (touched_required ? touched : true) ? errorMessage(error) : null
    }
  </Field>
);

const Condition = ({ when, is, children, is_not }) => (
  <Field name={when} subscription={{ value: true }}>
    {({ input: { value } }) => {
      let opposite = false
      let outcome

      if (is_not) {
        is = is_not;
        opposite = true
      }

      if (is === "present") {
        const isPresent = Array.isArray(value) ? value.length : !!value;

        outcome = isPresent ? children : null
      }
      else if (is === "blank") {
        const isPresent = Array.isArray(value) ? value.length : !!value;

        outcome = isPresent ? null : children
      }
      else if (Array.isArray(is)) {
        outcome = _.isEqual(_.sortBy(value), _.sortBy(is)) ? children : null
      }
      else if (typeof value === "boolean")
        outcome = String(value) === is ? children : null
      else {
        outcome = value === is ? children : null
      }

      if (opposite) {
        return outcome ? null : children
      }
      else {
        return outcome
      }
    }}
  </Field>
);

const DragHandle = sortableHandle(() => (
  <span className="drag-handler">
    <i className="fa fa-ellipsis-v"></i>
  </span>
));

export {
  Input,
  InputRow,
  RadioRow,
  Radio,
  Error,
  Condition,
  DragHandle,
};
