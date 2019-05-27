"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import axios from "axios";
import _ from "lodash";

import { Radio, Condition } from "../shared/components";

class BookingReservationForm extends React.Component {
  constructor(props) {
    super(props);
    // booking_reservation_form[found_customer]:
    // null:  doesn't find customer yet
    // true:  found customer
    // false: couldn't find customer
  };

  renderBookingHeader = () => {
    return (
      <div>
        {
          this.props.booking_page.shop_logo_url ? (
            <img className="logo" src={this.props.booking_page.shop_logo_url} />
          ) : (
            <strong>{this.props.booking_page.shop_name}</strong>
          )
        }
        Booking
      </div>
    )
  }

  findCustomer = async (form, values) => {
    try {
      const { customer_first_name, customer_last_name, customer_phone_number, remember_me } = values.booking_reservation_form;

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
          remember_me: remember_me
        },
        responseType: "json"
      })

      form.change("booking_reservation_form[customer_info]", response.data.customer_info)
      form.change("booking_reservation_form[found_customer]", Object.keys(response.data.customer_info).length ? true : false)
    }
    catch(err) {
      console.info(err)
    }
    finally {
      this.findCustomerCall = null;
    }
  }

  renderRegularCustomersOption = (form, values) => {
    return (
      <div>
        <Condition when="booking_reservation_form[found_customer]" is_not="true">
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
          <Condition when="booking_reservation_form[regular]" is="yes">
            <Field
              name="booking_reservation_form[customer_last_name]"
              component="input"
              placeholder="last_name"
            />
            <Field
              name="booking_reservation_form[customer_first_name]"
              component="input"
              placeholder="first_name"
            />
            <Field
              name="booking_reservation_form[customer_phone_number]"
              component="input"
              placeholder="phone_number"
              type="tel"
            />
            <label>
              <Field
                name="booking_reservation_form[remember_me]"
                component="input"
                type="checkbox"
              />
              Remember Me
            </label>
            <a href="#" onClick={() => this.findCustomer(form, values)}>
              Find customer
            </a>
          </Condition>
        </Condition>
      </div>
    )
  }

  renderCurrentCustomerInfo = (form, values) => {
    const { simple_address, last_name, first_name } = values.booking_reservation_form.customer_info;
    return (
      <div>
        <Condition when="booking_reservation_form[found_customer]" is="true">
          <div>
            {simple_address}
          </div>
          <div>
            {last_name}
            {first_name}
            <a href="#" onClick={() => form.change("booking_reservation_form[found_customer]", null)}>
              Not me
            </a>
          </div>
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
              {this.renderCurrentCustomerInfo(form, values)}
            </form>
          )
        }}
      />
    )
  }
}

export default BookingReservationForm;
