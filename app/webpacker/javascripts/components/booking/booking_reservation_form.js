"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import axios from "axios";
import _ from "lodash";
import 'bootstrap-sass/assets/javascripts/bootstrap/modal';

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

  customerInfoFieldModalHideHandler = () => {
    $("#customer-info-modal").modal("show");
  }

  openCustomerInfoFeildModel = async (form, field_name) => {
    await form.change("booking_reservation_form[customer_info_field_name]", field_name)
    $("#customer-info-modal").modal("hide")
    $("#customer-info-field-modal").on("hidden.bs.modal", this.customerInfoFieldModalHideHandler);
    $("#customer-info-field-modal").modal("show")
  }

  renderCustomerInfoFieldModel = (form, values) => {
    const field_name = values.booking_reservation_form.customer_info_field_name;
    if (!field_name) return;

    return (
      <div className="modal fade" id="customer-info-field-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
              <h4 className="modal-title">
              </h4>
            </div>
            <div className="modal-body">
              <Condition when="booking_reservation_form[customer_info_field_name]" is="full_name">
                <Field
                  name="booking_reservation_form[customer_info][last_name]"
                  type="text"
                  component="input"
                />
                <Field
                  name="booking_reservation_form[customer_info][first_name]"
                  type="text"
                  component="input"
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="phonetic_full_name">
                <Field
                  name="booking_reservation_form[customer_info][phonetic_last_name]"
                  type="text"
                  component="input"
                />
                <Field
                  name="booking_reservation_form[customer_info][phonetic_first_name]"
                  type="text"
                  component="input"
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="phone_number">
                <Field
                  name="booking_reservation_form[customer_info][phone_number]"
                  type="text"
                  component="input"
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="email">
                <Field
                  name="booking_reservation_form[customer_info][email]"
                  type="text"
                  component="input"
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="address">
                <Field
                  name="booking_reservation_form[customer_info][address_details][postcode]"
                  type="text"
                  component="input"
                />
                <Field
                  name="booking_reservation_form[customer_info][address_details][city]"
                  type="text"
                  component="input"
                />
                <Field
                  name="booking_reservation_form[customer_info][address_details][region]"
                  type="text"
                  component="input"
                />
                <Field
                  name="booking_reservation_form[customer_info][address_details][street]"
                  type="text"
                  component="input"
                />
              </Condition>
            </div>
            <div className="modal-footer centerize">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  renderCustomerInfoModal = (form, values) => {
    return (
      <div className="modal fade" id="customer-info-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
              <h4 className="modal-title">
              </h4>
            </div>
            <div className="modal-body">
              <div>
                {values.booking_reservation_form.customer_info.first_name}
                {values.booking_reservation_form.customer_info.last_name}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel(form, "full_name")}>Edit Full Name</a>
              </div>
              <div>
                {values.booking_reservation_form.customer_info.phonetic_last_name}
                {values.booking_reservation_form.customer_info.phonetic_first_name}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel(form, "phonetic_full_name")}>Edit Phonetic Full Name</a>
              </div>
              <div>
                {values.booking_reservation_form.customer_info.phone_number}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel(form, "phone_number")}>Edit Phone number</a>
              </div>
              <div>
                {values.booking_reservation_form.customer_info.email}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel(form, "email")}>Edit Email</a>
              </div>
              <div>
                {values.booking_reservation_form.customer_info.full_address}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel(form, "address")}>Edit Address</a>
              </div>
            </div>
            <div className="modal-footer centerize">
            </div>
          </div>
        </div>
      </div>
    );
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
            <a href="#" onClick={() => $("#customer-info-modal").modal("show")}>Edit</a>
            {this.renderCustomerInfoModal(form, values)}
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
              {this.renderCustomerInfoFieldModel(form, values)}
            </form>
          )
        }}
      />
    )
  }
}

export default BookingReservationForm;
