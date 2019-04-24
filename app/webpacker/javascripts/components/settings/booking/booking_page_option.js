"use strict";

import React from "react";
import { Field } from "react-final-form";

const BookingPageOption = ({ i18n, field }) => {
  const { open_details, close_details, booking_option_required_time, minute } = i18n;

  return (
    <div className="booking-option-field" data-controller="collapse" data-collapse-status="closed">
      <div className="booking-option-info">
        <div className="booking-option-name">
          <b>
            <Field name={`${field}label`} value={field.label} >
              {({input}) => input.value}
            </Field>
          </b>
        </div>

        <Field name={`${field}minutes`} value={field.minutes} >
          {({input}) => `${booking_option_required_time}${input.value}${minute}`}
        </Field>
      </div>

      <div className="booking-option-row">
        <span>
          <Field name={`${field}price`} value={field.price} >
            {({input}) => input.value}
          </Field>
        </span>
        <span className="booking-option-details-toggler" data-action="click->collapse#toggle">
          <a className="toggler-link" data-target="collapse.openToggler">{close_details}<i className="fa fa-chevron-up" aria-hidden="true"></i></a>
          <a className="toggler-link" data-target="collapse.closeToggler">{open_details}<i className="fa fa-chevron-down" aria-hidden="true"></i></a>
        </span>
      </div>
      <div className="booking-option-row" data-target="collapse.content">
        <Field name={`${field}memo`} value={field.memo} >
          {({input}) => (input.value || "No details")}
        </Field>
      </div>
    </div>
  );
}

export default BookingPageOption;
