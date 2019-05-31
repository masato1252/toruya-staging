"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import arrayMutators from 'final-form-arrays'
import axios from "axios";
import _ from "lodash";
import 'bootstrap-sass/assets/javascripts/bootstrap/modal';

import { Radio, Condition } from "../shared/components";
import Calendar from "../shared/calendar/calendar";
import BookingPageOption from "./booking_page_option";
import moment from 'moment-timezone';

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

  renderRegularCustomersOption = () => {
    return (
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
          <a href="#" onClick={() => this.findCustomer()}>
            Find customer
          </a>
        </Condition>
      </Condition>
    )
  }

  renderCustomerInfoFieldModel = () => {
    const field_name = this.booking_reservation_form_values.customer_info_field_name;
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

  renderCustomerInfoModal = () => {
    const { last_name, first_name, phonetic_last_name, phonetic_first_name, phone_number, email, full_address } = this.booking_reservation_form_values.customer_info;

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
                {first_name}
                {last_name}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel("full_name")}>Edit Full Name</a>
              </div>
              <div>
                {phonetic_last_name}
                {phonetic_first_name}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel("phonetic_full_name")}>Edit Phonetic Full Name</a>
              </div>
              <div>
                {phone_number}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel("phone_number")}>Edit Phone number</a>
              </div>
              <div>
                {email}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel("email")}>Edit Email</a>
              </div>
              <div>
                {full_address}
                <a href="#" onClick={() => this.openCustomerInfoFeildModel("address")}>Edit Address</a>
              </div>
            </div>
            <div className="modal-footer centerize">
            </div>
          </div>
        </div>
      </div>
    );
  }

  renderBookingFlowOptions = () => {
    return (
      <div>
        <div className="regular-customer-options">
          <div className="radio">
            <Field name="booking_reservation_form[booking_flow]" type="radio" value="booking_option_first" component={Radio}>
              Option first
            </Field>
          </div>
          <div className="radio">
            <Field name="booking_reservation_form[booking_flow]" type="radio" value="booking_date_first" component={Radio}>
              Date first
            </Field>
          </div>
        </div>
      </div>
    )
  }

  renderAvailableBookingOption = () => {
    const { booking_options, booking_at, booking_times } = this.booking_reservation_form_values;

    if (!booking_at) return;

    const available_booking_options = _.filter(booking_options, (booking_option) => {
      return _.includes(booking_times[booking_at], booking_option.id)
    })

    return (
      <div className="result-fields">
        {available_booking_options.map((booking_option_value) => {
          return <BookingPageOption
            key={`booking_options-${booking_option_value.id}`}
            booking_option_value={booking_option_value}
            selectBookingOptionCallback={this.selectBookingOption}
            i18n={this.props.i18n}
          />
        })}
      </div>
    )
  };

  renderBookingOptionFirstFlow = () => {
    const { booking_options, booking_times, booking_date, booking_at, booking_option_id } = this.booking_reservation_form_values;

    const selected_booking_option = _.find(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })

    return (
      <Condition when="booking_reservation_form[booking_flow]" is="booking_option_first">
        <Condition when="booking_reservation_form[booking_option_id]" is="blank">
          <div className="result-fields">
            {booking_options.map((booking_option_value) => {
              return <BookingPageOption
                key={`booking_options-${booking_option_value.id}`}
                booking_option_value={booking_option_value}
                selectBookingOptionCallback={this.selectBookingOption}
                i18n={this.props.i18n}
              />
            })}
          </div>
        </Condition>

        <Condition when="booking_reservation_form[booking_option_id]" is="present">
          <BookingPageOption
            key={`booking_options-${booking_option_id}`}
            booking_option_value={selected_booking_option}
            i18n={this.props.i18n}
          />
          <a href="#" onClick={this.optionFlowResetBookingOption}>Edit</a>
          <Condition when="booking_reservation_form[booking_at]" is="blank">
            <div className="booking-calendar">
              <Calendar
                {...this.props.calendar}
                dateSelectedCallback={this.fetchBookingTimes}
                scheduleParams={{
                  booking_option_id: booking_option_id
                }}
              />
              {
                (booking_times && Object.keys(booking_times).length) ? (
                  Object.keys(booking_times).map((time) => (
                    <div className="time-interval" key={`booking-time-${time}`} onClick={() => this.setBookingTimeAt(time)}>{time}~</div>)
                  )
                ) : (
                  <div>No available booking times</div>
                )
              }
            </div>
          </Condition>
        </Condition>

        <Condition when="booking_reservation_form[booking_at]" is="present">
          <div>
            {booking_date} {booking_at}
            <a href="#" onClick={this.optionFlowResetBookingAt}>Edit</a>
          </div>
          <div>
            <button onClick={this.onSubmit}>Booking</button>
          </div>
        </Condition>
      </Condition>
    )
  }

  renderBookingDateFirstFlow = () => {
    const { booking_options, booking_times, booking_date, booking_at, booking_option_id } = this.booking_reservation_form_values;

    const selected_booking_option = _.find(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })

    return (
      <Condition when="booking_reservation_form[booking_flow]" is="booking_date_first">
        <Condition when="booking_reservation_form[booking_at]" is="blank">
          <div className="booking-calendar">
            <Calendar
              {...this.props.calendar}
              dateSelectedCallback={this.fetchBookingTimes}
            />
            {
              (booking_times && Object.keys(booking_times).length) ? (
                Object.keys(booking_times).map((time) => (
                  <div className="time-interval" key={`booking-time-${time}`} onClick={() => this.setBookingTimeAt(time)}>{time}~</div>)
                )
              ) : (
                <div>No available booking times</div>
              )
            }
          </div>
        </Condition>

        <Condition when="booking_reservation_form[booking_at]" is="present">
          <div>
            {booking_date} {booking_at}
            <a href="#" onClick={this.dateFlowResetBookingAt}>Edit</a>
          </div>
          <Condition when="booking_reservation_form[booking_option_id]" is="blank">
            {this.renderAvailableBookingOption()}
          </Condition>
        </Condition>

        <Condition when="booking_reservation_form[booking_option_id]" is="present">
          <BookingPageOption
            key={`booking_options-${booking_option_id}`}
            booking_option_value={selected_booking_option}
            i18n={this.props.i18n}
          />
          <a href="#" onClick={this.dateFlowResetBookingOption}>Edit</a>
          <button onClick={this.onSubmit}>Booking</button>
        </Condition>
      </Condition>
    )
  }

  renderCurrentCustomerInfo = () => {
    const { simple_address, last_name, first_name } = this.booking_reservation_form_values.customer_info;

    return (
      <Condition when="booking_reservation_form[found_customer]" is="true">
        <div>
          {simple_address}
        </div>
        <div>
          {last_name}
          {first_name}
          <a href="#" onClick={() => this.booking_reservation_form.change("booking_reservation_form[found_customer]", null)}>
            Not me
          </a>
          <a href="#" onClick={() => $("#customer-info-modal").modal("show")}>Edit</a>
          {this.renderCustomerInfoModal()}
          {this.renderBookingFlowOptions()}
          {this.renderBookingOptionFirstFlow()}
          {this.renderBookingDateFirstFlow()}
        </div>
      </Condition>
    )
  }

  render() {
    return (
      <Form
        action={this.props.path.save}
        onSubmit={this.onSubmit}
        initialValues={{
          booking_reservation_form: { ...(this.props.booking_reservation_form) },
        }}
        mutators={{
          ...arrayMutators,
        }}
        render={({ handleSubmit, submitting, values, form }) => {
          this.booking_reservation_form = form;
          this.booking_reservation_form_values = values.booking_reservation_form;

          return (
            <form
              action={this.props.path.save}
              id="booking_reservation_form"
              className="booking-page"
              onSubmit={handleSubmit}
              acceptCharset="UTF-8"
              data-remote="true"
              method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />
              {this.renderBookingHeader()}
              {this.renderRegularCustomersOption()}
              {this.renderCurrentCustomerInfo()}
              {this.renderCustomerInfoFieldModel()}
            </form>
          )
        }}
      />
    )
  }

  fetchBookingTimes = async (date) => {
    this.booking_reservation_form.change("booking_reservation_form[booking_date]", date)

    const response = await axios({
      method: "GET",
      url: this.props.calendar.dateSelectedCallbackPath,
      params: {
        date: date,
        booking_option_id: this.booking_reservation_form_values.booking_option_id
      },
      responseType: "json"
    })

    if (Object.keys(response.data.booking_times).length) {
      this.booking_reservation_form.change("booking_reservation_form[booking_times]", response.data.booking_times)
    } else {
      this.booking_reservation_form.change("booking_reservation_form[booking_times]", [])
    }
  }

  setBookingTimeAt = (time) => {
    this.booking_reservation_form.change("booking_reservation_form[booking_at]", time)
  }

  selectBookingOption = (booking_option_id) => {
    this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", booking_option_id)
  }

  findCustomer = async () => {
    try {
      const { customer_first_name, customer_last_name, customer_phone_number, remember_me } = this.booking_reservation_form_values;

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

      this.booking_reservation_form.change("booking_reservation_form[customer_info]", response.data.customer_info)
      this.booking_reservation_form.change("booking_reservation_form[found_customer]", Object.keys(response.data.customer_info).length ? true : false)
    }
    catch(err) {
      console.info(err)
    }
    finally {
      this.findCustomerCall = null;
    }
  }

  onSubmit = async (event) => {
    event.preventDefault()

    const response = await axios({
      method: "POST",
      url: this.props.path.save,
      params: _.pick(
        this.booking_reservation_form_values,
        "customer_first_name",
        "customer_last_name",
        "customer_phone_number",
        "customer_info",
        "booking_date",
        "booking_at",
        "booking_option_id"
      ),
      responseType: "json"
    })

    if (response.data.status === "successful") {
      alert("Successful")
    }
  };

  customerInfoFieldModalHideHandler = () => {
    $("#customer-info-modal").modal("show");
  }

  openCustomerInfoFeildModel = async (field_name) => {
    await this.booking_reservation_form.change("booking_reservation_form[customer_info_field_name]", field_name)
    $("#customer-info-modal").modal("hide")
    $("#customer-info-field-modal").on("hidden.bs.modal", this.customerInfoFieldModalHideHandler);
    $("#customer-info-field-modal").modal("show")
  }

  dateFlowResetBookingAt = async () => {
    await Promise.all(
      this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", null),
      this.booking_reservation_form.change("booking_reservation_form[booking_times]", null),
      this.booking_reservation_form.change("booking_reservation_form[booking_at]", null)
    )
    this.booking_reservation_form.change("booking_reservation_form[booking_date]", moment().format("YYYY-MM-DD"))
  }

  dateFlowResetBookingOption = () => {
    this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", null)
  }

  optionFlowResetBookingAt = async () => {
    await Promise.all(
      this.booking_reservation_form.change("booking_reservation_form[booking_times]", null),
      this.booking_reservation_form.change("booking_reservation_form[booking_at]", null)
    )
    this.booking_reservation_form.change("booking_reservation_form[booking_date]", moment().format("YYYY-MM-DD"))
  }

  optionFlowResetBookingOption = async () => {
    await Promise.all(
      this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", null),
      this.booking_reservation_form.change("booking_reservation_form[booking_times]", null),
      this.booking_reservation_form.change("booking_reservation_form[booking_at]", null)
    )
    this.booking_reservation_form.change("booking_reservation_form[booking_date]", moment().format("YYYY-MM-DD"))
  }
}

export default BookingReservationForm;
