import React from "react";

const displayErrors = (form_values, error_reasons) => {
  let error_messages = [];
  let message_or_error_type = null
  let message_or_warning_type = null

  error_reasons.forEach((error_reason) => {
    ["errors", "warnings"].forEach((error_type) => {
      message_or_error_type = _.get(form_values[error_type], error_reason)

      if (typeof(message_or_error_type) === "object") {
        Object.keys(message_or_error_type).forEach((cause) => {
          if (cause) {
            error_messages.push(_displayErrors(form_values, [`${error_reason}${cause}`]))
          }
        })
      }
      else if (message_or_error_type) {
        error_messages.push(_displayErrors(form_values, [error_reason]))
      }
    })
  })

  return error_messages;
};

const _displayErrors = (form_values, error_reasons) => {
  let error_messages = [];
  let message = null;

  error_reasons.forEach((error_reason) => {
    if (message = _.get(form_values.warnings, error_reason)) {
      error_messages.push(<span className="warning" key={error_reason}>{message}</span>)
    }

    if (message = _.get(form_values.errors, error_reason)) {
      error_messages.push(<span className="danger" key={error_reason}>{message}</span>)
    }
  })

  return _.compact(error_messages);
};

export {
  displayErrors,
};
