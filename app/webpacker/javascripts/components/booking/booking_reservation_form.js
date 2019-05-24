"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import axios from "axios";
import _ from "lodash";

import { Radio, Condition } from "../shared/components";

class BookingReservationForm extends React.Component {
  constructor(props) {
    super(props);
  };

  renderBookingHeader = () => {
    return (
      <div>
        <img className="logo" src={this.props.booking_page.shop_logo_url} />
      </div>
    )
  }

  findCustomer = async (form, values) => {
    const { customer_first_name, customer_last_name, customer_phone_number } = values.booking_reservation_form;

    if (!(customer_first_name && customer_last_name && customer_phone_number)) {
      return;
    }

    if (this.findCustomerCall) {
      return;
    }

    this.findCustomerCall = "loading";

    const response = await axios({
      method: "GET",
      url: this.props.path.find_customer,
      params: {
        customer_first_name: customer_first_name,
        customer_last_name: customer_last_name,
        customer_phone_number: customer_phone_number,
      },
      responseType: "json"
    })

    form.change("booking_reservation_form[found_customer_info]", response.data.found_customer_info)
    form.change("booking_reservation_form[found_customer]", response.data.found_customer_info ? true : false)
    this.findCustomerCall = null;
  }

  renderRegularCustomersOption = (form, values) => {
    return (
      <div>
        <div className="regular-customer-options">
          <div className="radio">
            <Field name="booking_reservation_form[regular]" type="radio" value="yes" component={Radio}>
              Regular
            </Field>
          </div>
          <div className="radio">
            <Field name="booking_reservation_form[regular]" type="radio" value="no" component={Radio}>
              New
            </Field>
          </div>
        </div>
        <Condition when="booking_reservation_form[found_existing_customer]" is_not="true">
          <Condition when="booking_reservation_form[regular]" is="yes">
            <Field
              name="booking_reservation_form[customer_last_name]"
              component="input"
              placeholder="last_name"
            />
            <Field
              name="booking_reservation_form[customer_first_name]"
              component="input"
              placeholder="last_name"
            />
            <Field
              name="booking_reservation_form[customer_phone_number]"
              component="input"
              placeholder="phone_number"
              type="tel"
            />
            <a href="#" onClick={() => this.findCustomer(form, values)}>
              Find customer
            </a>
          </Condition>
        </Condition>
      </div>
    )
  }

  onSubmit = (values) => {
    $("#booking_reservation_form").submit()
  };

  render() {
    return (
      <Form
        action={this.props.path.save}
        onSubmit={this.onSubmit}
        initialValues={{
          booking_reservation_form: { ...(this.props.booking_reservation_form) },
        }}
        mutators={{
        }}
        id="booking_reservation_form"
        render={({ handleSubmit, submitting, values, form }) => {
          return (
            <form
              action={this.props.path.save}
              className="booking-page"
              onSubmit={handleSubmit}
              acceptCharset="UTF-8"
              method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />
              {this.renderBookingHeader()}
              {this.renderRegularCustomersOption(form, values)}
            </form>
          )
        }}
      />
    )
  }
}

export default BookingReservationForm;
