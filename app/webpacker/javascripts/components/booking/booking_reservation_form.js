"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import arrayMutators from 'final-form-arrays'
import axios from "axios";
import _ from "lodash";
import moment from 'moment-timezone';
import createFocusDecorator from "final-form-focus";
import createChangesDecorator from "final-form-calculate";
import 'bootstrap-sass/assets/javascripts/bootstrap/modal';

import { Radio, Condition, Error } from "../shared/components";
import Calendar from "../shared/calendar/calendar";
import BookingPageOption from "./booking_page_option";
import { requiredValidation, emailFormatValidator, lengthValidator, mustBeNumber, composeValidators } from "../../libraries/helper";

class BookingReservationForm extends React.Component {
  constructor(props) {
    // booking_reservation_form[found_customer]:
    // null:  doesn't find customer yet
    // true:  found customer
    // false: couldn't find customer
    super(props);
    moment.locale("ja");
    const { is_single_option, is_single_booking_time } = this.props.booking_page

    this.focusOnError = createFocusDecorator();
    this.calculator = createChangesDecorator(
      {
        field: /regular/,
        updates: async (value, name, allValues) => {
          if (is_single_option) {
            return await this.resetValues([
              "customer_last_name",
              "customer_first_name",
              "customer_phone_number",
              "customer_info",
              "found_customer"
            ]);
          } else {
            return await this.resetValues([
              "customer_last_name",
              "customer_first_name",
              "customer_phone_number",
              "customer_info",
              "booking_date",
              "booking_at",
              "booking_times",
              "booking_option_id",
              "found_customer"
            ]);
          }
        }
      },
      {
        field: /booking_flow/,
        updates: async (value, name, allValues) => {
          return await this.resetValues([
            "booking_date",
            "booking_at",
            "booking_times",
            "booking_option_id"
          ]);
        }
      }
    )
  };

  componentDidMount = () => {
    const { is_single_option, is_single_booking_time } = this.props.booking_page
    const { booking_options, single_booking_time } = this.booking_reservation_form_values

    if (is_single_booking_time && is_single_option) {
      const selected_booking_option = booking_options[0];

      this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", selected_booking_option.id)
      this.booking_reservation_form.change("booking_reservation_form[booking_date]", single_booking_time.booking_date)
      this.booking_reservation_form.change("booking_reservation_form[booking_at]", single_booking_time.booking_at)
    } else if (is_single_option) {
      const selected_booking_option = booking_options[0];

      this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", selected_booking_option.id)
    }
  }

  renderBookingHeader = (pristine) => {
    const { title, greeting, shop_logo_url } = this.props.booking_page;

    return (
      <div className="header">
        <div className="header-title-part">
          { shop_logo_url &&  <img className="logo" src={shop_logo_url} /> }
          <strong className="page-title">{title}</strong>
        </div>

        {pristine && !this.booking_reservation_form_values.is_done && <div className="greeting">{greeting}</div>}
      </div>
    )
  }

  renderRegularCustomersOption = () => {
    const { found_customer, is_finding_customer } = this.booking_reservation_form_values;

    if (found_customer) return;

    const { ever_used, yes_ever_used, no_first_time, name, last_name, first_name, phone_number, remember_me, confirm_customer_info } = this.props.i18n;
    const { shop_name } = this.props.booking_page;

    return (
      <div className="customer-type-options">
        <div className="regular-customer-options">
          <h4>
            {ever_used}{shop_name}
          </h4>

          <div className="radios">
            <div className="radio">
              <Field name="booking_reservation_form[regular]" type="radio" value="yes" component={Radio}>
                {yes_ever_used}
              </Field>
            </div>
            <div className="radio">
              <Field name="booking_reservation_form[regular]" type="radio" value="no" component={Radio}>
                {no_first_time}
              </Field>
            </div>
          </div>
        </div>

        <Condition when="booking_reservation_form[regular]" is="yes">
          <h4>
            {name}
          </h4>
          <Field
            name="booking_reservation_form[customer_last_name]"
            component="input"
            placeholder={last_name}
            type="text"
          />
          <Field
            name="booking_reservation_form[customer_first_name]"
            component="input"
            placeholder={first_name}
            type="text"
          />
          <h4>
            {phone_number}
          </h4>
          <Field
            name="booking_reservation_form[customer_phone_number]"
            component="input"
            placeholder="0123456789"
            type="tel"
          />
          <div className="remember-me">
            <label>
              <Field
                name="booking_reservation_form[remember_me]"
                component="input"
                type="checkbox"
              />
              {remember_me}
            </label>
          </div>
          <div className="centerize">
            <a href="#" className="btn btn-tarco" onClick={this.findCustomer} disabled={is_finding_customer}>
              {is_finding_customer ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : confirm_customer_info}
            </a>
          </div>
        </Condition>
      </div>
    )
  }

  renderCustomerInfoFieldModel = () => {
    const field_name = this.booking_reservation_form_values.customer_info_field_name;
    if (!field_name) return;

    const {
      name, last_name, first_name, phonetic_name, phonetic_last_name, phonetic_first_name,
      phone_number, email, save_change, invalid_to_change, info_change_title, address_details
    } = this.props.i18n;
    const is_field_error = this.booking_reservation_form_errors &&
      this.booking_reservation_form_errors.customer_info &&
      this.booking_reservation_form_errors.customer_info[field_name]
    return (
      <div className="modal fade" id="customer-info-field-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              { is_field_error ? null : (
                <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
              )}
              <h4 className="modal-title">
                {info_change_title}
              </h4>
            </div>
            <div className="modal-body">
              <Condition when="booking_reservation_form[customer_info_field_name]" is="full_name">
                <h4>
                  {name}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][last_name]"
                  type="text"
                  component="input"
                  placeholder={last_name}
                />
                <Field
                  name="booking_reservation_form[customer_info][first_name]"
                  type="text"
                  component="input"
                  placeholder={first_name}
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="phonetic_full_name">
                <h4>
                  {phonetic_name}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][phonetic_last_name]"
                  type="text"
                  component="input"
                  placeholder={phonetic_last_name}
                />
                <Field
                  name="booking_reservation_form[customer_info][phonetic_first_name]"
                  type="text"
                  component="input"
                  placeholder={phonetic_first_name}
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="phone_number">
                <h4>
                  {phone_number}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][phone_number]"
                  type="number"
                  component="input"
                  placeholder="01234567891"
                  validate={composeValidators(this, requiredValidation, mustBeNumber, lengthValidator(11))}
                />
                <Error
                  name="booking_reservation_form[customer_info][phone_number]"
                  touched_required={false}
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="email">
                <h4>
                  {email}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][email]"
                  type="text"
                  component="input"
                  placeholder="mail@domail.com"
                  className="email-field"
                  validate={composeValidators(this, requiredValidation, emailFormatValidator)}
                />
                <Error
                  name="booking_reservation_form[customer_info][email]"
                  touched_required={false}
                />
              </Condition>

              <Condition when="booking_reservation_form[customer_info_field_name]" is="address_details">
                <h4>
                  {address_details.zipcode}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][address_details][postcode]"
                  type="number"
                  component="input"
                  validate={composeValidators(this, requiredValidation, mustBeNumber, lengthValidator(7))}
                />
                <Error
                  name="booking_reservation_form[customer_info][address_details][postcode]"
                  touched_required={false}
                />
                <h4>
                  {address_details.living_state}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][address_details][region]"
                  type="text"
                  component="input"
                />
                <h4>
                  {address_details.city}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][address_details][city]"
                  type="text"
                  component="input"
                />
                <h4>
                  {address_details.street}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][address_details][street]"
                  type="text"
                  component="input"
                  className="street-field"
                />
              </Condition>
            </div>
            <div className="modal-footer centerize">
              { is_field_error ? (
                <button type="button" className="btn btn-tarco disabled" disabled="true">
                  {invalid_to_change}
                </button>
              ) : (
                <button type="button" className="btn btn-tarco" data-dismiss="modal" aria-label="Close">
                  {save_change}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    )
  }

  renderCustomerInfoModal = () => {
    const { last_name, first_name, phonetic_last_name, phonetic_first_name, phone_number, email, full_address } = this.booking_reservation_form_values.customer_info;
    const { i18n } = this.props

    return (
      <div className="modal fade" id="customer-info-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
              <h4 className="modal-title">
                {i18n.info_change_title}
              </h4>
            </div>
            <div className="modal-body">
              <h4>
                {i18n.name}
                <a href="#" className="edit" onClick={() => this.openCustomerInfoFeildModel("full_name")}>{i18n.edit}</a>
              </h4>
              <div className="info">
                {last_name} {first_name}
              </div>
              <h4>
                {i18n.phonetic_name}
                <a href="#" className="edit" onClick={() => this.openCustomerInfoFeildModel("phonetic_full_name")}>{i18n.edit}</a>
              </h4>
              <div className="info">
                {phonetic_last_name} {phonetic_first_name}
              </div>
              <h4>
                {i18n.phone_number}
                <a href="#" className="edit" onClick={() => this.openCustomerInfoFeildModel("phone_number")}>{i18n.edit}</a>
              </h4>
              <div className="info">
                {phone_number}
                <Error
                  name="booking_reservation_form[customer_info][phone_number]"
                  touched_required={false}
                />
              </div>
              <h4>
                {i18n.email}
                <a href="#" className="edit" onClick={() => this.openCustomerInfoFeildModel("email")}>{i18n.edit}</a>
              </h4>
              <div className="info">
                {email}
                <Error
                  name="booking_reservation_form[customer_info][email]"
                  touched_required={false}
                />
              </div>
              <h4>
                {i18n.address}
                <a href="#" className="edit" onClick={() => this.openCustomerInfoFeildModel("address_details")}>{i18n.edit}</a>
              </h4>
              <div className="info">
                {full_address}
                <Error
                  name="booking_reservation_form[customer_info][address_details][postcode]"
                  touched_required={false}
                />
              </div>
            </div>
            <div className="modal-footer centerize">
              <button type="button" className="btn btn-tarco" data-dismiss="modal" aria-label="Close">
                OK
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  renderBookingFlowOptions = () => {
    if (!this.isBookingFlowStart()) return;
    if (this.isFlowSelected()) return;
    const { flow_label, date_flow_first, option_flow_first } = this.props.i18n

    return (
      <div>
        <div className="regular-customer-options">
          <h4>
            {flow_label}
          </h4>
          <div className="radios">
            <div className="radio">
              <Field name="booking_reservation_form[booking_flow]" type="radio" value="booking_date_first" component={Radio}>
                {date_flow_first}
              </Field>
            </div>
            <div className="radio">
              <Field name="booking_reservation_form[booking_flow]" type="radio" value="booking_option_first" component={Radio}>
                {option_flow_first}
              </Field>
            </div>
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
      <div className="result-fields booking-options">
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
    if (!this.isBookingFlowStart()) return;

    const { booking_options, booking_times, booking_date, booking_at, booking_option_id } = this.booking_reservation_form_values;
    const { edit, please_select_a_menu } = this.props.i18n;

    const selected_booking_option = _.find(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })

    return (
      <Condition when="booking_reservation_form[booking_flow]" is="booking_option_first">
        <Condition when="booking_reservation_form[booking_option_id]" is="blank">
          <div className="result-fields booking-options">
            <h4>
              {please_select_a_menu}
            </h4>
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
          {this.renderSelectedBookingOption(this.resetFlowValues)}
          <Condition when="booking_reservation_form[booking_at]" is="blank">
            {this.renderBookingCalendar()}
          </Condition>
        </Condition>

        <Condition when="booking_reservation_form[booking_at]" is="present">
          <div>
            {this.renderBookingDatetime(() => this.resetValues(["booking_date", "booking_at", "booking_times"]))}
          </div>
        </Condition>
      </Condition>
    )
  }

  renderBookingDateFirstFlow = () => {
    if (!this.isBookingFlowStart()) return;

    const { booking_options, booking_times, booking_date, booking_at, booking_option_id } = this.booking_reservation_form_values;
    const { edit } = this.props.i18n;

    return (
      <Condition when="booking_reservation_form[booking_flow]" is="booking_date_first">
        <Condition when="booking_reservation_form[booking_at]" is="blank">
          {this.renderBookingCalendar()}
        </Condition>

        <Condition when="booking_reservation_form[booking_at]" is="present">
          <div>
            {this.renderBookingDatetime(this.resetFlowValues)}
          </div>
          <Condition when="booking_reservation_form[booking_option_id]" is="blank">
            {this.renderAvailableBookingOption()}
          </Condition>
        </Condition>

        <Condition when="booking_reservation_form[booking_option_id]" is="present">
          {this.renderSelectedBookingOption(() => this.resetValues(["booking_option_id"]))}
        </Condition>
      </Condition>
    )
  }

  renderCurrentCustomerInfo = () => {
    const { found_customer } = this.booking_reservation_form_values;
    const { simple_address, last_name, first_name } = this.booking_reservation_form_values.customer_info;

    if (!found_customer) return;

    const { not_me, edit_info, of, sir, thanks_for_come_back } = this.props.i18n

    return (
      <div className="customer-found">
        <div>
          {thanks_for_come_back}
        </div>
        <div>
          <div className="simple-address">
            {simple_address}{of}
          </div>
          <div className="customer-full-name">
            {last_name} {first_name} {sir}
          </div>
        </div>
        <div className="edit-customer-info">
          <a href="#" onClick={() => $("#customer-info-modal").modal("show")}>{edit_info}</a>
          {this.renderCustomerInfoModal()}
        </div>
        <div className="not-me">
          <a href="#" onClick={() => this.booking_reservation_form.change("booking_reservation_form[found_customer]", null)}>
            {last_name} {first_name} {not_me}
          </a>
        </div>
      </div>
    )
  }

  renderNewCustomerFields = () => {
    if (!this.isBookingFlowEnd()) return;

    const { name, last_name, first_name, phonetic_name, phonetic_last_name, phonetic_first_name, phone_number, email, remember_me } = this.props.i18n;

    return (
      <Condition when="booking_reservation_form[regular]" is="no">
        <h4>
          {name}
        </h4>
        <div className="field">
          <Field
            name="booking_reservation_form[customer_last_name]"
            component="input"
            placeholder={last_name}
            type="text"
            validate={composeValidators(this, requiredValidation)}
          />
          <Error name="booking_reservation_form[customer_last_name]" />
        </div>
        <div className="field">
          <Field
            name="booking_reservation_form[customer_first_name]"
            component="input"
            placeholder={first_name}
            type="text"
            validate={composeValidators(this, requiredValidation)}
          />
          <Error name="booking_reservation_form[customer_first_name]" />
        </div>
        <h4>
          {phonetic_name}
        </h4>
        <div className="field">
          <Field
            name="booking_reservation_form[customer_phonetic_last_name]"
            component="input"
            placeholder={phonetic_last_name}
            type="text"
            validate={composeValidators(this, requiredValidation)}
          />
          <Error name="booking_reservation_form[customer_phonetic_last_name]" />
        </div>
        <div className="field">
          <Field
            name="booking_reservation_form[customer_phonetic_first_name]"
            component="input"
            placeholder={phonetic_first_name}
            type="text"
            validate={composeValidators(this, requiredValidation)}
          />
          <Error name="booking_reservation_form[customer_phonetic_first_name]" />
        </div>
        <h4>
          {phone_number}
        </h4>
        <Field
          name="booking_reservation_form[customer_phone_number]"
          component="input"
          placeholder="0123456789"
          type="number"
          validate={composeValidators(this, requiredValidation, mustBeNumber, lengthValidator(11))}
        />
        <Error name="booking_reservation_form[customer_phone_number]" />
        <h4>
          {email}
        </h4>
        <Field
          name="booking_reservation_form[customer_email]"
          component="input"
          placeholder="mail@domail.com"
          type="email"
          validate={composeValidators(this, requiredValidation, emailFormatValidator)}
        />
        <Error name="booking_reservation_form[customer_email]" />
        <div className="remember-me">
          <label>
            <Field
              name="booking_reservation_form[remember_me]"
              component="input"
              type="checkbox"
            />
            {remember_me}
          </label>
        </div>
      </Condition>
    )
  }

  renderBookingReservationButton = () => {
    const { regular } = this.booking_reservation_form_values;

    if (!this.isBookingFlowEnd()) return;
    if (!this.isEnoughCustomerInfo() && regular !== "no") return;

    return (
      <div className="reservation-confirmation">
        <div className="note">
          {this.props.booking_page.note}
        </div>

        <button
          onClick={(event) => {
            this.handleSubmit(event)
            if (Object.keys(this.booking_reservation_form_errors).length &&
              Object.keys(this.booking_reservation_form_errors.customer_info).length) {
              this.customerInfoFieldModalHideHandler()
            }
          }}
        className="btn btn-tarco" disabled={this.submitting}>
          {this.submitting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            this.props.i18n.confirm_reservation
          )}
        </button>
      </div>
    )
  }

  renderSelectedBookingOption = (resetValuesCallback = false) => {
    const { booking_options, booking_option_id, booking_date, booking_at } = this.booking_reservation_form_values
    const { please_select_a_menu, edit } = this.props.i18n;

    if (!booking_option_id) return;

    const selected_booking_option = _.find(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })

    const selected_booking_option_content = (
      <div className="selected-booking-option" id="selected-booking-option">
        <i className="fa fa-check-circle"></i>
        <BookingPageOption
          key={`booking_options-${selected_booking_option.id}`}
          booking_option_value={selected_booking_option}
          i18n={this.props.i18n}
          booking_start_at={moment.tz(`${booking_date} ${booking_at}`, this.props.timezone)}
        />
      </div>
    )

    if (resetValuesCallback) {
      return (
        <div>
          <h4>
            {please_select_a_menu}
            <a href="#" className="edit" onClick={resetValuesCallback}>{edit}</a>
          </h4>
          {selected_booking_option_content}
        </div>
      )
    }

    return selected_booking_option_content
  }

  renderBookingDatetime = (resetValuesCallback = false) => {
    const { booking_date, booking_at} = this.booking_reservation_form_values
    if (!(booking_date && booking_at)) return;

    const { edit, time_from } = this.props.i18n;

    return (
      <div className="selected-booking-datetime" id="selected-booking-datetime">
        <i className="fa fa-calendar"></i>
        {moment.tz(`${booking_date} ${booking_at}`, this.props.timezone).format("llll")} {time_from}
        {resetValuesCallback && <a href="#" className="edit" onClick={resetValuesCallback}>{edit}</a>}
      </div>
    )
  }

  renderBookingCalendar = () => {
    const { booking_times, booking_date, booking_at, booking_option_id } = this.booking_reservation_form_values;
    if (booking_date && booking_at) return;

    const {
      booking_dates_calendar_hint,
      booking_dates_working_date,
      booking_dates_available_booking_date,
      date,
      start_time,
      no_available_booking_times
    } = this.props.i18n;

    return (
      <div className="booking-calendar">
        <h4>
          {date}
        </h4>
        {booking_dates_calendar_hint}
        <Calendar
          {...this.props.calendar}
          skip_default_date={true}
          dateSelectedCallback={this.fetchBookingTimes}
          scheduleParams={{
            booking_option_id: booking_option_id
          }}
        />
        <div className="demo-days">
          <div className="demo-day day booking-available"></div>
          {booking_dates_available_booking_date}
          <div className="demo-day day workDay"></div>
          {booking_dates_working_date}
        </div>
        <h4>
          {start_time}
        </h4>
        {
          (booking_times && Object.keys(booking_times).length) ? (
            Object.keys(booking_times).map((time) => (
              <div className="time-interval" key={`booking-time-${time}`} onClick={() => this.setBookingTimeAt(time)}>{time}~</div>)
            )
          ) : (
            booking_date && <div className="warning">{no_available_booking_times}</div>
          )
        }
      </div>
    )
  }

  renderBookingDownView = () => {
    const {
      title,
      message1,
      message2,
      desc1,
      desc2,
      desc3,
      feature1,
      feature2,
      feature3,
      signup_now
    } = this.props.i18n.done

    return (
      <div className="done-view">
        <h3 className="title">
          {title}
        </h3>
        <div className="message">
          {message1}
          <br />
          {message2}
        </div>
        <div className="desc">
          {this.props.booking_page.shop_name}{desc1}
          <br />
          {desc2}
          <br />
          {desc3}
        </div>
        <div>
          <img className="toruya-logo" src={this.props.toruya_logo} />
        </div>
        <div className="feature-list">
          <div>
            <i className="fa fa-check-square"></i>
            {feature1}
          </div>
          <div>
            <i className="fa fa-check-square"></i>
            {feature2}
          </div>
          <div>
            <i className="fa fa-check-square"></i>
            {feature3}
          </div>
        </div>
        <div>
          <a href="https://toruya.com" className="btn btn-gray">{signup_now}</a>
        </div>
      </div>
    )
  }

  renderBookingStartedYetView = () => {
    const {
      title,
      message1,
      message2
    } = this.props.i18n.start_yet

    return (
      <div className="start-yet-view">
        <h3 className="title">
          {title}
        </h3>
        <div className="message">
          {message1}
          <br />
          <strong>{this.props.booking_page.start_at}～</strong>
          <br />
          {message2}
        </div>
      </div>
    )
  }

  renderBookingEndedView = () => {
    const {
      title,
      message1,
      message2
    } = this.props.i18n.ended

    return (
      <div className="ended-view">
        <h3 className="title">
          {title}
        </h3>
        <div className="message">
          {message1}
          <br />
          {message2}
        </div>
      </div>
    )
  }

  renderBookingFlow = () => {
    const { is_single_option, is_single_booking_time, is_started, is_ended } = this.props.booking_page
    const { booking_options, special_date, booking_option_id, regular, is_done } = this.booking_reservation_form_values
    const { edit } = this.props.i18n;

    if (is_done) {
      return this.renderBookingDownView()
    }

    if (!is_started) {
      return this.renderBookingStartedYetView()
    }

    if (is_ended) {
      return this.renderBookingEndedView()
    }

    if (is_single_booking_time && is_single_option) {
      return (
        <div>
          {this.renderBookingDatetime()}
          {this.renderSelectedBookingOption()}
          {this.renderRegularCustomersOption()}
          {this.renderCurrentCustomerInfo()}
          {this.renderNewCustomerFields()}
          {this.renderBookingReservationButton()}
        </div>
      )
    } else if (is_single_option) {
      return (
        <div>
          {this.renderSelectedBookingOption()}
          {this.renderBookingCalendar()}
          {this.renderBookingDatetime(this.isBookingFlowEnd() && (() => this.resetValues(["booking_date", "booking_at", "booking_times"])))}
          {this.isBookingFlowEnd() && this.renderRegularCustomersOption()}
          {this.isBookingFlowEnd() && this.renderCurrentCustomerInfo()}
          {this.isBookingFlowEnd() && this.renderNewCustomerFields()}
          {this.renderBookingReservationButton()}
        </div>
      )
    } else {
      return (
        <div>
          {this.renderRegularCustomersOption()}
          {this.renderCurrentCustomerInfo()}
          {this.renderBookingFlowOptions()}
          {this.renderBookingOptionFirstFlow()}
          {this.renderBookingDateFirstFlow()}
          {this.renderNewCustomerFields()}
          {this.renderBookingReservationButton()}
        </div>
      )
    }

  }

  render() {
    return (
      <Form
        action={this.props.path.save}
        onSubmit={this.onSubmit}
        initialValues={{
          booking_reservation_form: { ...(this.props.booking_reservation_form) },
        }}
        decorators={[this.focusOnError, this.calculator]}
        mutators={{
          ...arrayMutators,
        }}
        render={({ handleSubmit, submitting, values, errors, form, pristine }) => {
          this.booking_reservation_form = form;
          this.booking_reservation_form_values = values.booking_reservation_form;
          this.handleSubmit = handleSubmit
          this.submitting = submitting
          this.booking_reservation_form_errors = errors.booking_reservation_form

          return (
            <form
              action={this.props.path.save}
              id="booking_reservation_form"
              className="booking-page"
              onSubmit={handleSubmit}
              acceptCharset="UTF-8"
              method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />
              {this.renderBookingHeader(pristine)}
              {this.renderBookingFlow()}

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

  setBookingTimeAt = async (time) => {
    await this.booking_reservation_form.change("booking_reservation_form[booking_at]", time)
    this.scrolloToView()
  }

  selectBookingOption = async (booking_option_id) => {
    await this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", booking_option_id)
    this.scrolloToView()
  }

  findCustomer = async (event) => {
    event.preventDefault();

    const { customer_first_name, customer_last_name, customer_phone_number, remember_me } = this.booking_reservation_form_values;

    if (!(customer_first_name && customer_last_name && customer_phone_number)) {
      return;
    }

    if (this.findCustomerCall) {
      return;
    }

    this.booking_reservation_form.change("booking_reservation_form[is_finding_customer]", true)
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
    this.booking_reservation_form.change("booking_reservation_form[is_finding_customer]", null)
    this.findCustomerCall = null;
  }

  onSubmit = async (event) => {
    if (this.bookingReserationLoading) {
      return;
    }

    this.bookingReserationLoading = "loading";

    const response = await axios({
      method: "POST",
      url: this.props.path.save,
      params: _.merge(
        { authenticity_token: this.props.form_authenticity_token },
        _.pick(
          this.booking_reservation_form_values,
          "customer_first_name",
          "customer_last_name",
          "customer_phone_number",
          "customer_info",
          "booking_date",
          "booking_at",
          "booking_option_id",
          "customer_phonetic_last_name",
          "customer_phonetic_first_name",
          "customer_email",
          "remember_me"
        ),
      ),
      responseType: "json"
    })

    this.bookingReserationLoading = null;

    if (response.data.status === "successful") {
      this.booking_reservation_form.change("booking_reservation_form[is_done]", true)
    }
  };

  customerInfoFieldModalHideHandler = () => {
    $("#customer-info-modal").modal("show");
  }

  openCustomerInfoFeildModel = async (field_name) => {
    await this.booking_reservation_form.change("booking_reservation_form[customer_info_field_name]", field_name)
    $("#customer-info-modal").modal("hide")
    $("#customer-info-field-modal").on("hidden.bs.modal", this.customerInfoFieldModalHideHandler);
    $("#customer-info-field-modal").modal({
      backdrop: "static",
      keyboard: false,
      show: true
    })
  }

  resetFlowValues = async () => {
    this.resetValues([
      "booking_option_id",
      "booking_date",
      "booking_at",
      "booking_times"
    ])
  }

  resetValues = (fields) => {
    let newBaokingForm = {}

    fields.forEach((field) => {
      let resetValue = null;

      switch (field) {
        case "customer_info":
          resetValue = {}
          break;
        case "booking_times":
          resetValue = []
          break;
      }

      this.booking_reservation_form.change(`booking_reservation_form[${field}]`, resetValue)
    })

    return {};
  }

  isBookingFlowStart = () => {
    return this.booking_reservation_form_values.found_customer || this.booking_reservation_form_values.regular === "no"
  }

  isBookingFlowEnd = () => {
    const { booking_option_id, booking_date, booking_at } = this.booking_reservation_form_values;

    return booking_option_id && booking_date && booking_at
  }

  isFlowSelected = () => {
    const { booking_option_id, booking_date, booking_at } = this.booking_reservation_form_values;

    return booking_option_id || (booking_date && booking_at)
  }

  isEnoughCustomerInfo = () => {
    const {
      customer_info,
      customer_last_name,
      customer_first_name,
      customer_phonetic_last_name,
      customer_phonetic_first_name,
      customer_phone_number,
      customer_email,
      found_customer
    } = this.booking_reservation_form_values;

    return (found_customer && customer_info && customer_info.id) || (
      customer_last_name &&
      customer_first_name &&
      customer_phonetic_last_name &&
      customer_phonetic_first_name &&
      customer_phone_number &&
      customer_email
    )
  }

  scrolloToView = () => {
    const { booking_flow } = this.booking_reservation_form_values;
    let scroll_to;

    if (booking_flow === "booking_date_first") {
      scroll_to = "selected-booking-datetime"
    }
    else if (booking_flow === "booking_option_first") {
      scroll_to = "selected-booking-option"
    }

    document.getElementById(scroll_to).scrollIntoView();
  }
}

export default BookingReservationForm;
