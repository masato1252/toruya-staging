"use strict";

import React from "react";
import Rails from "rails-ujs";
import { Form, Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import arrayMutators from 'final-form-arrays'
import axios from "axios";
import _ from "lodash";
import moment from 'moment-timezone';
import arrayMove from "array-move"
import createFocusDecorator from "final-form-focus";
import createChangesDecorator from "final-form-calculate";
import { CSSTransition } from 'react-transition-group'
import 'bootstrap-sass/assets/javascripts/bootstrap/modal';
import { SlideDown } from 'react-slidedown';

import { Radio, Condition, Error, ErrorMessage } from "shared/components";
import { BookingStartInfo, BookingEndInfo, AddLineFriendInfo, CheckInLineBtn, LineLoginBtn } from "shared/booking";
import Calendar from "shared/calendar/calendar";
import BookingPageOption from "./booking_page_option";
import { requiredValidation, emailFormatValidator, lengthValidator, mustBeNumber, composeValidators } from "libraries/helper";
import StripeCheckoutForm from "shared/stripe_checkout_form"
import I18n from 'i18n-js/index.js.erb';

class BookingReservationForm extends React.Component {
  constructor(props) {
    // booking_reservation_form[found_customer]:
    // null:  doesn't find customer yet
    // true:  found customer
    // false: couldn't find customer
    super(props);
    moment.locale("ja");
    const { is_single_option } = this.props.booking_page

    this.focusOnError = createFocusDecorator();
    this.calculator = createChangesDecorator(
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

  renderDraftWarning = () => {
    if (this.props.booking_page.draft) {
      return (
        <div className="alert alert-info">{this.props.i18n.showing_preview}</div>
      )
    }
  }

  renderBookingHeader = (pristine) => {
    const {
      title,
      greeting,
      shop_logo_url,
      shop_name
    } = this.props.booking_page;

    return (
      <div className="header">
        <div className="header-title-part">
          <h1>
            { shop_logo_url ?  <img className="logo" src={shop_logo_url} /> : shop_name }
          </h1>
          <h2 className="page-title">{title}</h2>
        </div>

        {pristine && !this.booking_reservation_form_values.is_done && <div className="greeting">{greeting}</div>}
      </div>
    )
  }

  renderSocialCustomerLogin = () => {
    const { social_user_id, customer_without_social_account, booking_option_id, booking_date, booking_at } = this.booking_reservation_form_values

    return (
      <div className="social-login-block centerize">
        <LineLoginBtn
          social_account_login_url={`${this.props.social_account_login_url}&booking_option_id=${booking_option_id}&booking_date=${booking_date}&booking_at=${booking_at}`}>
          <h3 className="desc" dangerouslySetInnerHTML={{ __html: I18n.t("booking_page.message.line_reminder_messages_html") }} />
        </LineLoginBtn>
      </div>
    )
  }

  renderRegularCustomersOption = () => {
    const {
      found_customer,
      is_finding_customer,
    } = this.booking_reservation_form_values;

    if (found_customer) return;
    if (this.isCustomerTrusted()) return;

    const { name, last_name, first_name, phonetic_last_name, phonetic_first_name, phone_number, confirm_customer_info } = this.props.i18n;
    const { shop_name } = this.props.booking_page;

    return (
      <div className="customer-type-options">
        <h4>
          {name}
        </h4>
        <div>
          <Field
            name="booking_reservation_form[customer_last_name]"
            component="input"
            placeholder={last_name}
            type="text"
            validate={(value) => requiredValidation(phonetic_last_name)(this, value)}
          />
          <Error name="booking_reservation_form[customer_last_name]" />
          <Field
            name="booking_reservation_form[customer_first_name]"
            component="input"
            placeholder={first_name}
            type="text"
            validate={(value) => requiredValidation(phonetic_first_name)(this, value)}
          />
          <Error name="booking_reservation_form[customer_first_name]" />
        </div>
        <br />
        <div>
          <Field
            name="booking_reservation_form[customer_phonetic_last_name]"
            component="input"
            placeholder={phonetic_last_name}
            type="text"
            validate={(value) => requiredValidation(phonetic_last_name)(this, value)}
          />
          <Error name="booking_reservation_form[customer_phonetic_last_name]" />
          <Field
            name="booking_reservation_form[customer_phonetic_first_name]"
            component="input"
            placeholder={phonetic_first_name}
            type="text"
            validate={(value) => requiredValidation(phonetic_first_name)(this, value)}
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
          type="tel"
        />
        <Condition when="booking_reservation_form[found_customer]" is="null">
          <div className="centerize">
            <a href="#" className="btn btn-tarco find-customer" onClick={this.findCustomer} disabled={is_finding_customer}>
              {is_finding_customer ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : confirm_customer_info}
            </a>
          </div>
        </Condition>
      </div>
    )
  }

  renderBookingCode = () => {
    const {
      found_customer,
      is_confirming_code,
      is_asking_confirmation_code,
      booking_code,
      use_default_customer,
      booking_code_failed_message,
    } = this.booking_reservation_form_values;

    if (this.neverTryToFindCustomer()) return;
    if (this.isCustomerTrusted()) return;

    const { i18n } = this.props;

    return (
      <div className="customer-type-options">
        <h4>
          {i18n.booking_code.code}
        </h4>
        <div className="centerize">
          <div className="desc">
            {i18n.message.booking_code_message}
          </div>
          <Field
            className="booking-code"
            name="booking_reservation_form[booking_code][code]"
            component="input"
            placeholder="012345"
            type="tel"
          />
          <button
            onClick={this.confirmCode}
          className="btn btn-tarco" disabled={is_confirming_code || is_asking_confirmation_code}>
            {is_confirming_code ? (
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
            ) : (
              i18n.confirm
            )}
          </button>
          <ErrorMessage error={booking_code_failed_message} />
          <div className="resend-row">
            <a href="#"
              onClick={this.askConfirmCode}
              disabled={is_confirming_code || is_asking_confirmation_code}
            >
              {is_asking_confirmation_code ? (
                <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
              ) : (
                i18n.booking_code.resend
              )}
            </a>
          </div>
        </div>
      </div>
    );
  }

  renderCustomerInfoFieldModel = () => {
    const field_name = this.booking_reservation_form_values.customer_info_field_name;
    if (!field_name) return;

    const {
      name, last_name, first_name, phonetic_name, phonetic_last_name, phonetic_first_name,
      phone_number, email, save_change, invalid_to_change, info_change_title, address_details,
      select_region
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
                  validate={composeValidators(this, requiredValidation(phone_number), mustBeNumber, lengthValidator(11))}
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
                  validate={composeValidators(this, requiredValidation(email), emailFormatValidator)}
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
                  name="booking_reservation_form[customer_info][address_details][zip_code]"
                  type="number"
                  component="input"
                  validate={composeValidators(this, requiredValidation(address_details.zipcode), mustBeNumber, lengthValidator(7))}
                />
                <Error
                  name="booking_reservation_form[customer_info][address_details][zip_code]"
                  touched_required={false}
                />
                <h4>
                  {address_details.living_state}
                </h4>
                <Field name="booking_reservation_form[customer_info][address_details][region]" component="select">
                  <option value=""> {select_region} </option>
                  {this.props.booking_page.regions.map((region) => (
                    <option value={region.value} key={region.value}>
                      {region.label}
                    </option>
                  ))}
                </Field>
                <h4>
                  {address_details.city}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][address_details][city]"
                  type="text"
                  component="input"
                />
                <h4>
                  {address_details.street1}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][address_details][street1]"
                  type="text"
                  component="input"
                  className="street-field"
                />
                <h4>
                  {address_details.street2}
                </h4>
                <Field
                  name="booking_reservation_form[customer_info][address_details][street2]"
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
    const { last_name, first_name, phonetic_last_name, phonetic_first_name, phone_number, email, address_details } = this.booking_reservation_form_values.customer_info;
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
                {address_details && address_details.zip_code && `〒${address_details.zip_code.substring(0,3)}-${address_details.zip_code.substring(4, -1)}`} {address_details && address_details.region} {address_details && address_details.city} {address_details && address_details.street1} {address_details && address_details.street2}
                <Error
                  name="booking_reservation_form[customer_info][address_details][zip_code]"
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

  sorted_booking_options = (booking_options, last_selected_option_id) => {
    const matched_index = booking_options.findIndex(option => option.id === last_selected_option_id);

    if (matched_index > 0) {
      return arrayMove(booking_options, matched_index, 0);
    }
    else {
      return booking_options
    }
  }

  renderAvailableBookingOption = () => {
    const {
      booking_options,
      booking_at,
      booking_times,
      last_selected_option_id,
    } = this.booking_reservation_form_values;

    if (!booking_at) return;

    const available_booking_options = _.filter(booking_options, (booking_option) => {
      return _.includes(booking_times[booking_at], booking_option.id)
    })

    return (
      <div className="result-fields booking-options">
        {this.sorted_booking_options(available_booking_options, last_selected_option_id).map((booking_option_value) => {
          return <BookingPageOption
            key={`booking_options-${booking_option_value.id}`}
            booking_option_value={booking_option_value}
            last_selected_option_id={last_selected_option_id}
            selectBookingOptionCallback={this.selectBookingOption}
            i18n={this.props.i18n}
          />
        })}
      </div>
    )
  };

  renderBookingOptionFirstFlow = () => {
    const {
      booking_options,
      booking_times,
      booking_date,
      booking_at,
      booking_option_id,
      last_selected_option_id,
    } = this.booking_reservation_form_values;
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
            {this.sorted_booking_options(booking_options, last_selected_option_id).map((booking_option_value) => {
              return <BookingPageOption
                key={`booking_options-${booking_option_value.id}`}
                booking_option_value={booking_option_value}
                last_selected_option_id={last_selected_option_id}
                selectBookingOptionCallback={this.selectBookingOption}
                i18n={this.props.i18n}
              />
            })}
          </div>
        </Condition>

        <Condition when="booking_reservation_form[booking_option_id]" is="present">
          {this.renderSelectedBookingOption(this.resetFlowValues)}

            {this.renderBookingCalendar()}
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
    const { booking_options, booking_times, booking_date, booking_at, booking_option_id } = this.booking_reservation_form_values;
    const { edit } = this.props.i18n;

    return (
      <Condition when="booking_reservation_form[booking_flow]" is="booking_date_first">
        {this.renderBookingCalendar()}

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
    const { customer_last_name, customer_first_name } = this.booking_reservation_form_values;
    const { not_me, edit_info, of, sir, thanks_for_come_back } = this.props.i18n

    if (!this.isCustomerTrusted()) return;

    if (found_customer) {
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
            <a href="#" onClick={() => {
              this.booking_reservation_form.change("booking_reservation_form[found_customer]", null)
              this.booking_reservation_form.change("booking_reservation_form[use_default_customer]", false)
            }}>
              {last_name} {first_name} {not_me}
            </a>
          </div>
        </div>
      )
    }
    else {
      return (
        <div className="customer-found">
          <div className="customer-full-name">
            {customer_last_name} {customer_first_name} {sir}
          </div>
        </div>
      )
    }
  }

  renderBookingFailedArea = () => {
    const {
      booking_failed,
      booking_failed_message
    } = this.booking_reservation_form_values;
    const { reset_button } = this.props.i18n;
    const { is_single_option } = this.props.booking_page

    if (!booking_failed) return;

    return (
      <div className="booking-failed-message">
        <ErrorMessage error={booking_failed_message} />
        {
          (!is_single_option) &&
          <button onClick={this.resetBookingFailedValues} className="btn btn-orange reset">
            {reset_button}
          </button>
        }
      </div>
    )
  }

  renderBookingReservationButton = () => {
    const { booking_failed, booking_code, booking_options, booking_option_id } = this.booking_reservation_form_values;
    const { reminder_desc } = this.props.i18n;

    if (!this.isBookingFlowEnd()) return;
    if (!this.isEnoughCustomerInfo()) return;
    if (!this.isCustomerTrusted()) return;

    const selected_booking_option = _.find(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })

    return (
      <div className="reservation-confirmation">
        <div className="note">
          {this.props.booking_page.note}
        </div>

        <div className="reminder-permission">
          <label>
            <Field
              name="booking_reservation_form[reminder_permission]"
              component="input"
              type="checkbox"
            />
            {reminder_desc}
          </label>
        </div>

        <a href="#"
          className="btn btn-tarco"
          onClick={(event) => {
            if (this.isAnyErrors()) {
              this.customerInfoFieldModalHideHandler()
            }
            else if (this.props.stripe_key && this.props.booking_page.online_payment_enabled && !selected_booking_option.is_free) {
              this.booking_reservation_form.change("booking_reservation_form[is_paying_booking]", true)
            }
            else {
              this.handleSubmit(null, event)
            }
          }}
          disabled={this.submitting}
        >
          {this.submitting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            this.props.i18n.confirm_reservation
          )}
        </a>
        {this.renderBookingFailedArea()}
      </div>
    )
  }

  renderSelectedBookingOption = (resetValuesCallback = false) => {
    const {
      booking_options,
      booking_option_id,
      booking_date,
      booking_at,
      last_selected_option_id,
    } = this.booking_reservation_form_values
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
          last_selected_option_id={last_selected_option_id}
          i18n={this.props.i18n}
          booking_start_at={moment.tz(`${booking_date} ${booking_at}`, "YYYY-MM-DD HH:mm", this.props.timezone)}
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
    const {
      booking_date,
      booking_at,
    } = this.booking_reservation_form_values
    if (!(booking_date && booking_at)) return;

    const { edit, time_from } = this.props.i18n;

    return (
      <div className="selected-booking-datetime" id="selected-booking-datetime">
        <i className="fa fa-calendar"></i>
        {moment.tz(`${booking_date} ${booking_at}`, "YYYY-MM-DD HH:mm", this.props.timezone).format("llll")} {time_from}
        {resetValuesCallback && <a href="#" className="edit" onClick={resetValuesCallback}>{edit}</a>}
      </div>
    )
  }

  renderBookingCalendar = () => {
    const {
      booking_times,
      booking_date,
      booking_at,
      booking_option_id,
    } = this.booking_reservation_form_values;

    const {
      booking_dates_calendar_hint,
      booking_dates_working_date,
      booking_dates_available_booking_date,
      date,
      start_time,
    } = this.props.i18n;

    return (
      <SlideDown className={'calendar-slidedown'}>
        {
          !booking_date || !booking_at ? (
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
              <h4 id="times_header">
                {booking_date && start_time}
              </h4>
              {this.renderBookingTimes()}
            </div>
          ) : null
        }
      </SlideDown>
    )
  }

  renderBookingTimes = () => {
    const {
      booking_times,
      booking_date,
      booking_at,
      is_fetching_booking_time,
    } = this.booking_reservation_form_values;

    const {
      booking_dates_calendar_hint,
      booking_dates_working_date,
      booking_dates_available_booking_date,
      date,
      start_time,
      no_available_booking_times
    } = this.props.i18n;

    if (is_fetching_booking_time) {
      return (
        <div className="spinner-loading">
          <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
        </div>
      )
    }
    else if (booking_times && Object.keys(booking_times).length) {
      return (
        <div>
          {Object.keys(booking_times).map((time, i) => (
            <div
              className={`time-interval ${time == booking_at ? "selected-time-item" : ""}`}
              key={`booking-time-${time}`}
              onClick={() => this.setBookingTimeAt(time)}>
              {time}~
            </div>)
          )}
        </div>
      )
    } else if (booking_date) {
      return <div className="warning">{no_available_booking_times}</div>
    }

  }

  renderChargingView = () => {
    const {
      booking_options,
      booking_date,
      booking_at,
      booking_option_id,
    } = this.booking_reservation_form_values;

    const { time_from } = this.props.i18n;

    const selected_booking_option = _.find(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })

    const booking_details = `${moment.tz(`${booking_date} ${booking_at}`, "YYYY-MM-DD HH:mm", this.props.timezone).format("llll")} ${time_from}`

    // TODO: handle failed case
    return (
      <div className="done-view">
        <StripeCheckoutForm
          stripe_key={this.props.stripe_key}
          handleToken={async (token) => {
            console.log("token", token)
            await this.booking_reservation_form.change("booking_reservation_form[stripe_token]", token)
            this.handleSubmit()
          }}
          header={selected_booking_option.name}
          desc={booking_details}
          pay_btn={I18n.t("action.pay")}
          details_desc={selected_booking_option.price}
        />
      </div>
    )
  }

  renderBookingDownView = () => {
    const { social_user_id } = this.booking_reservation_form_values
    const {
      title,
      message1,
      message2,
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

        <CheckInLineBtn social_account_add_friend_url={this.props.social_account_add_friend_url} />
      </div>
    )
  }

  renderBookingStartedYetView = () => {
    return (
      <>
        <BookingStartInfo start_at={this.props.booking_page.start_at} />
        <AddLineFriendInfo social_account_add_friend_url={this.props.social_account_add_friend_url} />
      </>
    )
  }

  renderBookingEndedView = () => {
    return (
      <>
        <BookingEndInfo />
        <AddLineFriendInfo social_account_add_friend_url={this.props.social_account_add_friend_url} />
      </>
    )
  }

  renderBookingFlow = () => {
    const { is_single_option, is_started, is_ended } = this.props.booking_page
    const { booking_options, special_date, booking_option_id, is_done, is_paying_booking } = this.booking_reservation_form_values
    const { edit } = this.props.i18n;

    if (is_done) {
      return this.renderBookingDownView()
    }

    if (is_paying_booking) {
      return (
        <div>
          {this.renderChargingView()}
          {this.renderBookingFailedArea()}
        </div>
      )
    }

    if (is_ended) {
      return this.renderBookingEndedView()
    }

    if (!is_started) {
      return this.renderBookingStartedYetView()
    }

    if (is_single_option) {
      return (
        <div>
          {this.renderSelectedBookingOption()}
          {this.renderBookingCalendar()}
          {this.renderBookingDatetime(this.isBookingFlowEnd() && (() => this.resetValues(["booking_date", "booking_at", "booking_times"])))}
          {this.isBookingFlowEnd() && !this.isSocialLoginChecked() && this.renderSocialCustomerLogin()}
          {this.isBookingFlowEnd() && this.isSocialLoginChecked() && this.renderRegularCustomersOption()}
          {this.isBookingFlowEnd() && this.isSocialLoginChecked() && this.renderBookingCode()}
          {this.isBookingFlowEnd() && this.isSocialLoginChecked() && this.renderCurrentCustomerInfo()}
          {this.isSocialLoginChecked() && this.renderBookingReservationButton()}
        </div>
      )
    } else {
      return (
        <div>
          {this.renderBookingFlowOptions()}
          {this.renderBookingOptionFirstFlow()}
          {this.renderBookingDateFirstFlow()}
          {this.isBookingFlowEnd() && !this.isSocialLoginChecked() && this.renderSocialCustomerLogin()}
          {this.isBookingFlowEnd() && this.isSocialLoginChecked() && this.renderRegularCustomersOption()}
          {this.isBookingFlowEnd() && this.isSocialLoginChecked() && this.renderBookingCode()}
          {this.isBookingFlowEnd() && this.isSocialLoginChecked() && this.renderCurrentCustomerInfo()}
          {this.isSocialLoginChecked() && this.renderBookingReservationButton()}
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
              {this.renderDraftWarning()}
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
    this.scrollToTarget("times_header")
    await this.booking_reservation_form.change("booking_reservation_form[booking_date]", date)

    this.booking_reservation_form.change("booking_reservation_form[is_fetching_booking_time]", true)
    const response = await axios({
      method: "GET",
      url: this.props.calendar.dateSelectedCallbackPath,
      params: {
        date: date,
        booking_option_id: this.booking_reservation_form_values.booking_option_id
      },
      responseType: "json"
    })

    this.booking_reservation_form.change("booking_reservation_form[is_fetching_booking_time]", null)
    if (Object.keys(response.data.booking_times).length) {
      await this.booking_reservation_form.change("booking_reservation_form[booking_times]", response.data.booking_times)
    } else {
      await this.booking_reservation_form.change("booking_reservation_form[booking_times]", [])
    }

    setTimeout(() => this.scrollToTarget("footer"), 1000)
  }

  setBookingTimeAt = async (time) => {
    await this.booking_reservation_form.change("booking_reservation_form[booking_at]", time)
    this.scrollToSelectedTarget()
  }

  selectBookingOption = async (booking_option_id) => {
    await this.booking_reservation_form.change("booking_reservation_form[booking_option_id]", booking_option_id)
    this.scrollToSelectedTarget()
  }

  findCustomer = async (event) => {
    event.preventDefault();

    const { customer_first_name, customer_last_name, customer_phone_number } = this.booking_reservation_form_values;

    if (!(customer_first_name && customer_last_name && customer_phone_number)) {
      return;
    }

    if (this.findCustomerCall) {
      return;
    }

    this.booking_reservation_form.change("booking_reservation_form[is_finding_customer]", true)
    this.booking_reservation_form.change("booking_reservation_form[booking_code_failed_message]", null)
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

    const {
      customer_info,
      last_selected_option_id,
      booking_code,
      errors
    } = response.data;

    this.booking_reservation_form.change("booking_reservation_form[customer_info]", customer_info)
    this.booking_reservation_form.change("booking_reservation_form[present_customer_info]", customer_info)
    this.booking_reservation_form.change("booking_reservation_form[found_customer]", Object.keys(customer_info).length ? true : false)
    this.booking_reservation_form.change("booking_reservation_form[last_selected_option_id]", last_selected_option_id)
    this.booking_reservation_form.change("booking_reservation_form[is_finding_customer]", null)
    this.booking_reservation_form.change("booking_reservation_form[booking_code]", booking_code)
    this.booking_reservation_form.change("booking_reservation_form[use_default_customer]", false)
    this.findCustomerCall = null;
  }

  askConfirmCode = async (event) => {
    event.preventDefault();

    if (this.askConfirmCodeCall) {
      return;
    }
    const { customer_phone_number, customer_last_name, customer_first_name } = this.booking_reservation_form_values;

    this.booking_reservation_form.change("booking_reservation_form[is_asking_confirmation_code]", true)
    this.booking_reservation_form.change("booking_reservation_form[booking_code_failed_message]", null)
    this.askConfirmCodeCall = "loading";

    const response = await axios({
      method: "GET",
      url: this.props.path.ask_confirmation_code,
      params: {
        customer_phone_number: customer_phone_number,
      },
      responseType: "json"
    })

    const {
      booking_code,
      errors
    } = response.data;

    this.booking_reservation_form.change("booking_reservation_form[booking_code]", booking_code)
    this.booking_reservation_form.change("booking_reservation_form[is_asking_confirmation_code]", false)
    this.askConfirmCodeCall = null;
  }

  confirmCode = async (event) => {
    event.preventDefault();

    if (this.confirmCodeCall) {
      return;
    }

    const { uuid, code } = this.booking_reservation_form_values.booking_code;

    this.booking_reservation_form.change("booking_reservation_form[is_confirming_code]", true)
    this.confirmCodeCall = "loading";

    const response = await axios({
      method: "GET",
      url: this.props.path.confirm_code,
      params: {
        uuid,
        code
      },
      responseType: "json"
    })

    const {
      booking_code,
      errors
    } = response.data;

    this.booking_reservation_form.change("booking_reservation_form[booking_code][passed]", booking_code.passed)
    this.booking_reservation_form.change("booking_reservation_form[is_confirming_code]", false)
    this.confirmCodeCall = null;

    if (errors) {
      this.booking_reservation_form.change("booking_reservation_form[booking_code_failed_message]", errors.message)
    }
  }

  onSubmit = async (event) => {
    const { is_paying_booking, stripe_token } = this.booking_reservation_form_values

    if (this.bookingReserationLoading) return;
    if (is_paying_booking && !stripe_token) return;

    this.bookingReserationLoading = "loading";

    axios.interceptors.response.use(function (response) {
      // Any status code that lie within the range of 2xx cause this function to trigger
      // Do something with response data
      return response;
    }, function (error) {
      // Any status codes that falls outside the range of 2xx cause this function to trigger
      // Do something with response error
      console.log(error)
      return Promise.reject(error);
    });

    try {
      const response = await axios({
        method: "POST",
        url: this.props.path.save,
        data: _.merge(
          {
            authenticity_token: Rails.csrfToken(),
          },
          _.pick(
            this.booking_reservation_form_values.booking_code,
            "uuid",
          ),
          _.pick(
            this.booking_reservation_form_values,
            "stripe_token",
            "booking_option_id",
            "booking_date",
            "booking_at",
            "customer_first_name",
            "customer_last_name",
            "customer_phonetic_last_name",
            "customer_phonetic_first_name",
            "customer_phone_number",
            "customer_info",
            "present_customer_info",
            "reminder_permission",
            "social_user_id"
          ),
        ),
        responseType: "json"
      })

      this.bookingReserationLoading = null;

      const { status, errors } = response.data;

      if (status === "successful") {
        this.booking_reservation_form.change("booking_reservation_form[is_done]", true)
      }
      else if (status === "failed") {
        this.booking_reservation_form.change("booking_reservation_form[booking_failed]", true)

        if (errors) {
          this.booking_reservation_form.change("booking_reservation_form[booking_failed_message]", errors.message)
          setTimeout(() => this.scrollToTarget("footer"), 200)
        }
      }
      else if (status === "invalid_authenticity_token") {
        location.reload()
      }
    }
    catch(error) {
      location.reload()
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

  resetBookingFailedValues = () => {
    const { is_single_option } = this.props.booking_page

    if (is_single_option) {
      this.resetValues([
        "booking_date",
        "booking_at",
        "booking_times"
      ])
    }
    else {
      this.resetFlowValues();
    }
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

    this.booking_reservation_form.change("booking_reservation_form[booking_failed]", null)

    return {};
  }

  isSocialLoginChecked = () => {
    const { social_user_id, customer_without_social_account } = this.booking_reservation_form_values

    return !this.props.social_account_login_required || social_user_id || customer_without_social_account
  }

  isBookingFlowEnd = () => {
    const { booking_option_id, booking_date, booking_at } = this.booking_reservation_form_values;

    return booking_option_id && booking_date && booking_at
  }

  isFlowSelected = () => {
    const { booking_option_id, booking_date, booking_at } = this.booking_reservation_form_values;

    return booking_option_id || (booking_date && booking_at)
  }

  neverTryToFindCustomer = () => {
    return this.booking_reservation_form_values.found_customer === null
  }

  isCustomerTrusted = () => {
    const { found_customer, use_default_customer, booking_code } = this.booking_reservation_form_values;

    return (use_default_customer && this.isEnoughCustomerInfo()) || (found_customer != null && booking_code && booking_code.passed)
  }

  isEnoughCustomerInfo = () => {
    const {
      customer_info,
      customer_last_name,
      customer_first_name,
      customer_phonetic_last_name,
      customer_phonetic_first_name,
      customer_phone_number,
      found_customer
    } = this.booking_reservation_form_values;

    return (found_customer && customer_info && customer_info.id) || (
      customer_last_name &&
      customer_first_name &&
      customer_phonetic_last_name &&
      customer_phonetic_first_name &&
      customer_phone_number
    )
  }

  isAnyErrors = () => {
    return this.booking_reservation_form_errors &&
      Object.keys(this.booking_reservation_form_errors).length &&
      this.booking_reservation_form_errors.customer_info &&
      Object.keys(this.booking_reservation_form_errors.customer_info).length
  }

  scrollToSelectedTarget = () => {
    const { booking_flow } = this.booking_reservation_form_values;
    let scroll_to;

    if (booking_flow === "booking_date_first") {
      scroll_to = "selected-booking-datetime"
    }
    else if (booking_flow === "booking_option_first") {
      scroll_to = "selected-booking-option"
    }

    this.scrollToTarget(scroll_to);
  }

  scrollToTarget = (target_id) => {
    if (document.getElementById(target_id)) {
      document.getElementById(target_id).scrollIntoView();
    }
  }
}

export default BookingReservationForm;
