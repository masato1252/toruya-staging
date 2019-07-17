"use strict";

import React from "react";
import { Form, Field, FormSpy } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import createFocusDecorator from "final-form-focus";
import createChangesDecorator from "final-form-calculate";
import { OnChange } from 'react-final-form-listeners'
import arrayMutators from 'final-form-arrays'
import moment from "moment-timezone";
import _ from "lodash";
import axios from "axios";

import { requiredValidation, transformValues } from "../../../../libraries/helper";
import { Input, InputRow, RadioRow, Radio, Error, Condition } from "../../../shared/components";
import CommonDatepickerField from "../../../shared/datepicker_field";
import DateFieldAdapter from "../../../shared/date_field_adapter";
import SelectMultipleInputs from "../../../shared/select_multiple_inputs";
import MultipleDatetimeInput from "../../../shared/multiple_datetime_input";
import BookingPageOption from "./booking_page_option";
import Calendar from "../../../shared/calendar/calendar";

class BookingPageSettings extends React.Component {
  constructor(props) {
    super(props);

    this.throttleVerifySpecialDates = _.throttle(this.verifySpecialDates, 200);
    this.focusOnError = createFocusDecorator();
    this.calculator = createChangesDecorator(
      {
        field: /special_dates_array_start_at_date_part_input|had_special_date|shop_id/, // when a field matching this pattern changes...
        updates: async (value, name, allValues) => {
          return await this.prefillBusinessTime(allValues);
        }
      },
      {
        field: /had_special_date|shop_id|interval|overlap_restriction|special_dates|options/, // when a field matching this pattern changes...
        updates: async (value, name, allValues) => {
          return await this.calculateBookingTimes(allValues);
        }
      },
      {
        field: /shop_id/,
        updates: async (value, name, allValues) => {
          return await this.fetchAvailableBookingOptions(allValues);
        }
      }
    )
  };

  componentDidMount = () => {
    this.initBookingTimes()
    this.initAvailableBookingOptions()
  }

  initBookingTimes = async () => {
    const booking_times = await this.calculateBookingTimes(this.booking_page_settings_values);

    this.booking_page_settings_form.change("booking_page[booking_times]", booking_times["booking_page[booking_times]"])
  }

  renderNameFields = () => {
    const { required_label, name_header, page_name, page_name_hint, title, title_hint, greeting, greeting_placeholder } = this.props.i18n;

    return (
      <div>
        <h3>{name_header}</h3>
        <div className="formRow">
          <Field
            name="booking_page[name]"
            component={InputRow}
            type="text"
            validate={(value) => requiredValidation(this, value, page_name)}
            label={page_name}
            hint={page_name_hint}
            requiredLabel={required_label}
          />

          <Field
            name="booking_page[title]"
            component={InputRow}
            type="text"
            validate={(value) => requiredValidation(this, value, title)}
            label={title}
            hint={title_hint}
            requiredLabel={required_label}
          />

          <Field
            name="booking_page[greeting]"
            component={InputRow}
            componentType="textarea"
            label={greeting}
            placeholder={greeting_placeholder}
            rows={10}
          />
        </div>
      </div>
    );
  }

  renderSelectedBookingOptionFields = (fields, collection_name) => {
    const { menu_time_span, menu_interval, minute } = this.props.i18n;

    return (
      <div className="result-fields booking-options-result">
        {fields.map((field, index) => {
          return (
            <div key={`${collection_name}-${index}`} className="result-field">
              <Field
                name={`${field}value`}
                value={field.value}
                component="input"
                type="hidden"
              />
              <BookingPageOption
                field={field}
                i18n={this.props.i18n}
              />

             <div className="booking-option-action">
               <a
                 href="#"
                 className="btn btn-symbol btn-orange after-field-btn"
                 onClick={(event) => {
                   event.preventDefault();
                   fields.remove(index)
                 }}
                 >
                 <i className="fa fa-minus" aria-hidden="true" ></i>
               </a>
               <div className="booking-option-period">
                 <Field
                   name={`${field}start_at`}
                   value={field.start_at}
                   >
                   {({input}) => input.value}
                 </Field>
                 ～
                 <Field
                   name={`${field}end_at`}
                   value={field.end_at}
                   >
                   {({input}) => input.value}
                 </Field>
                </div>
              </div>
              <Error
                name={field}
                touched_required={false}
              />
           </div>
          )
         })}
      </div>
    )
  };

  renderBookingOptionFields = () => {
    const { required_label, booking_option_header, select_a_booking_option, booking_option_hint } = this.props.i18n;
    const { available_booking_options } = this.booking_page_settings_values.booking_page;

    return (
      <div>
        <h3>{booking_option_header}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <dl>
            <Field
              name="booking_page[selected_booking_option]"
              collection_name="booking_page[options]"
              component={SelectMultipleInputs}
              resultFields={this.renderSelectedBookingOptionFields}
              options={available_booking_options}
              selectLabel={select_a_booking_option}
              hint={booking_option_hint}
              />
          </dl>
        </div>
      </div>
    );
  }

  renderShopFields = () => {
    const { required_label, shop_header } = this.props.i18n;

    return (
      <div>
        <h3>{shop_header}<strong>{required_label}</strong></h3>
        <div className="formRow">
          {this.props.shop_options.map((shop_option) =>
            <Field key={`shop-${shop_option.value}`} name="booking_page[shop_id]" type="radio" value={shop_option.value} component={RadioRow}>
              {shop_option.label}
            </Field>
          )}
        </div>
        <Error name="booking_page[shop_id]" />
      </div>
    );
  }

  renderBookingDateFields = (values) => {
    const {
      required_label,
      booking_dates_header,
      special_date_label,
      default_available_dates_label
    } = this.props.i18n;

    return (
      <div>
        <h3>{booking_dates_header}</h3>
        <div className="formRow">
          <dl>
            <dd>
              <div className="radio">
                <Field name="booking_page[had_special_date]" type="radio" value="false" component={Radio}>
                  {default_available_dates_label}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_page[had_special_date]" type="radio" value="true" component={Radio}>
                  {special_date_label}
                </Field>
                <Error name="booking_page[had_special_date]" />
              </div>
              {
                values.booking_page.had_special_date === "true" && (
                  <Field
                    name="special_dates_array"
                    collection_name="booking_page[special_dates]"
                    component={MultipleDatetimeInput}
                    timezone={this.props.timezone}
                    state_form={this.booking_page_settings_form}
                    i18n={this.props.i18n}
                  />
                )
              }
            </dd>
          </dl>
        </div>
      </div>
    );
  }

  renderBookingIntervalFields = () => {
    const {
      required_label,
      interval_header,
      interval_real_booking_time_warning,
      interval_option,
      per_minute,
      interval_example_html,
      no_available_booking_times
    } = this.props.i18n;

    return (
      <div>
        <h3>{interval_header}</h3>
        <div className="formRow">
          <dl>
            <dd>
              <div>
                {interval_option}
                <Field name="booking_page[interval]" component="select" className="interval-selector">
                  <option value="10">10</option>
                  <option value="15">15</option>
                  <option value="30">30</option>
                  <option value="60">60</option>
                </Field>
                {per_minute}
              </div>
              <div dangerouslySetInnerHTML={{ __html: interval_example_html }} />
            </dd>
          </dl>
        </div>
      </div>
    );
  }

  renderBookingPeriodFields = () => {
    const { required_label, sale_period, sale_start, sale_end, sale_now, sale_on, sale_forever } = this.props.i18n;

    return (
      <div>
        <h3>{sale_period}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <dl>
            <dt>{sale_start}</dt>
            <dd>
              <div className="radio">
                <Field name="booking_page[start_at_type]" type="radio" value="now" component={Radio}>
                  {sale_now}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_page[start_at_type]" type="radio" value="date" component={Radio}>
                  {sale_on}
                </Field>
              </div>
              <Condition when="booking_page[start_at_type]" is="date">
                <div>
                  <Field
                    name="booking_page[start_at_date_part]"
                    component={DateFieldAdapter}
                    date={moment.tz(this.props.timezone).format("YYYY-MM-DD")}
                    hiddenWeekDate={true}
                  />
                  <Field
                    name="booking_page[start_at_time_part]"
                    type="time"
                    component={Input}
                  />
                  <Error name="booking_page[start_at_time_part]" />
                </div>
              </Condition>
            </dd>
          </dl>
          <dl>
            <dt>{sale_end}</dt>
            <dd>
              <div className="radio">
                <Field name="booking_page[end_at_type]" type="radio" value="now" component={Radio}>
                  {sale_forever}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_page[end_at_type]" type="radio" value="date" component={Radio}>
                  {sale_on}
                </Field>
              </div>
              <Condition when="booking_page[end_at_type]" is="date">
                <div>
                  <Field
                    name="booking_page[end_at_date_part]"
                    component={DateFieldAdapter}
                    date={moment.tz(this.props.timezone).format("YYYY-MM-DD")}
                    timezone={this.props.timezone}
                    hiddenWeekDate={true}
                  />
                  <Field
                    name="booking_page[end_at_time_part]"
                    type="time"
                    component={Input}
                  />
                  <Error name="booking_page[end_at_time_part]" />
                </div>
              </Condition>
            </dd>
          </dl>
        </div>
      </div>
    );
  }

  renderBookingOverlapRestrictionField = () => {
    const { overlap_booking, not_allow_overlap_booking_label, allow_overlap_booking_label} = this.props.i18n;

    return (
      <div>
        <h3>{overlap_booking}</h3>
        <div className="formRow">
          <Field name="booking_page[overlap_restriction]" type="radio" value="true" component={RadioRow}>
            {not_allow_overlap_booking_label}
          </Field>
          <Field name="booking_page[overlap_restriction]" type="radio" value="false" component={RadioRow}>
            {allow_overlap_booking_label}
          </Field>
        </div>
        <Error name="booking_page[overlap_restriction]" />
      </div>
    )
  }

  renderBookingNoteField = () => {
    const { required_label, note_label, note_hint } = this.props.i18n;

    return (
      <div>
        <h3>{note_label}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <Field
            name="booking_page[note]"
            component={InputRow}
            componentType="textarea"
            validate={(value) => requiredValidation(this, value, note_label)}
            placeholder={note_label}
            rows={10}
          />
        </div>
      </div>
    );
  }

  calculateBookingTimes = async (allValues) => {
    const { shop_id, had_special_date, special_dates, options, overlap_restriction, interval } = allValues.booking_page;

    if (this.calculateBookingTimesCall) {
      this.calculateBookingTimesCall.cancel();
    }
    this.calculateBookingTimesCall = axios.CancelToken.source();

    if (!(shop_id &&
      had_special_date === "true" && special_dates && special_dates.length &&
      options && options.length == 1)) {
      return {
        "booking_page[booking_times]": []
      }
    }

    const response = await axios({
      method: "GET",
      url: this.props.path.booking_times,
      params: {
        shop_id: shop_id,
        special_dates: special_dates,
        booking_option_ids: options.map((option) => option.id),
        interval: interval,
        overlap_restriction: overlap_restriction
      },
      responseType: "json",
      cancelToken: this.calculateBookingTimesCall.token
    })

    if (!response.data.booking_times.length) {
      return {
        "booking_page[booking_times]": []
      }
    }

    return {
      "booking_page[booking_times]": response.data.booking_times
    }
  }

  prefillBusinessTime = async (allValues) => {
    const { shop_id, had_special_date } = allValues.booking_page;
    const { special_dates_array_start_at_date_part_input } = allValues;

    if (this.prefillBusinessTimeCall) {
      this.prefillBusinessTimeCall.cancel();
    }
    this.prefillBusinessTimeCall = axios.CancelToken.source();

    if (!(shop_id && had_special_date === "true" && special_dates_array_start_at_date_part_input )) {
      return {}
    }

    const response = await axios({
      method: "GET",
      url: this.props.path.business_time,
      params: {
        shop_id: shop_id,
        date: special_dates_array_start_at_date_part_input
      },
      responseType: "json",
      cancelToken: this.prefillBusinessTimeCall.token
    })

    return {
      special_dates_array_start_at_time_part_input: response.data.start_at_time_part,
      special_dates_array_end_at_time_part_input: response.data.end_at_time_part
    }
  }

  isSpecialDatesLegal = (special_dates) => {
    return (_.every(special_dates, (special_date) => special_date.start_at_date_part == special_date.end_at_date_part));
  }

  verifySpecialDates = async (values) => {
    const { shop_id, had_special_date, special_dates, options } = values.booking_page;

    if (!(shop_id && had_special_date === "true" && special_dates && special_dates.length && options && options.length)) {
      return {}
    }

    if (!this.isSpecialDatesLegal(special_dates)) {
      return {}
    }

    const response = await axios({
      method: "GET",
      url: this.props.path.validate_special_dates,
      params: {
        shop_id: shop_id,
        special_dates: special_dates,
        booking_option_ids: options.map((option) => option.id)
      },
      responseType: "json"
    })

    if (!response.data.message.length) {
      return {}
    }

    return { booking_page: { had_special_date: response.data.message }};
  }

  validate = (values) => {
    const { timezone } = this.props;
    const {
      errors,
      form_errors,
      booking_option_header,
      shop_header,
      time,
      sale_start,
      sale_end,
    } = this.props.i18n;
    const fields_errors = {};
    fields_errors.booking_page = {};
    const {
      shop_id,
      available_booking_options,
      options,
      start_at_type,
      start_at_date_part,
      start_at_time_part,
      end_at_type,
      end_at_date_part,
      end_at_time_part,
      had_special_date,
      special_dates,
    } = values.booking_page || {};

    if (!options.length) {
      fields_errors.booking_page.selected_booking_option = `${booking_option_header}${errors.required}`;
    }

    if (!shop_id) {
      fields_errors.booking_page.shop_id = `${shop_header}${errors.required}`;
    }

    if (start_at_type === "date" && !start_at_time_part) {
      fields_errors.booking_page.start_at_time_part = `${sale_start}${errors.required}`;
    }

    if (end_at_type === "date" && !end_at_time_part) {
      fields_errors.booking_page.end_at_time_part = `${sale_end}${errors.required}`;
    }

    if (had_special_date === "true" && !special_dates.length) {
      fields_errors.booking_page.had_special_date = `${time}${errors.required}`;
    }

    if (had_special_date === "true" && special_dates.length && start_at_type === "date" && start_at_date_part && start_at_time_part) {
      const earistSpecialDate = _.minBy(special_dates, (special_date) => moment.tz(`${special_date.start_at_date_part} ${special_date.start_at_time_part}`, timezone))
      const specialDateStartAt = moment.tz(`${earistSpecialDate.start_at_date_part} ${earistSpecialDate.start_at_time_part}`, "YYYY-MM-DD HH:mm", timezone)
      const bookingStartAt = moment.tz(`${start_at_date_part} ${start_at_time_part}`, "YYYY-MM-DD HH:mm", timezone)

      if (bookingStartAt.isAfter(specialDateStartAt)) {
        const start_at_error_message = form_errors.start_at_too_late.replace("{datetime}", specialDateStartAt.format("YYYY/M/D HH:mm"))

        fields_errors.booking_page.start_at_date_part = start_at_error_message;
        fields_errors.booking_page.start_at_time_part = start_at_error_message;
      }
    }

    if (had_special_date === "true" && special_dates.length && end_at_type === "date" && end_at_date_part && end_at_time_part) {
      const latestSpecialDate = _.maxBy(special_dates, (special_date) => moment.tz(`${special_date.end_at_date_part} ${special_date.end_at_time_part}`, "YYYY-MM-DD HH:mm", timezone))
      const specialDateEndAt = moment.tz(`${latestSpecialDate.end_at_date_part} ${latestSpecialDate.end_at_time_part}`, "YYYY-MM-DD HH:mm", timezone)
      const bookingEndAt = moment.tz(`${end_at_date_part} ${end_at_time_part}`, "YYYY-MM-DD HH:mm", timezone)

      if (bookingEndAt.isBefore(specialDateEndAt)) {
        const end_at_error_message = form_errors.end_at_too_early.replace("{datetime}", specialDateEndAt.format("YYYY/M/D HH:mm"))

        fields_errors.booking_page.end_at_date_part = end_at_error_message;
        fields_errors.booking_page.end_at_time_part = end_at_error_message;
      }
    }

    if (options.length) {
      const available_booking_option_ids = _.map(available_booking_options, (available_booking_option) => available_booking_option.id)
      const shop_name = this.props.shop_options.find((shop_option) => shop_option.value == shop_id).label

      options.forEach((option, i) => {
        if (!_.includes(available_booking_option_ids, option.id)) {
          fields_errors.booking_page.options = fields_errors.booking_page.options || []
          fields_errors.booking_page.options[i] = form_errors.unavailable_booking_option.replace("{shop_name}", shop_name)
        }
      })
    }

    return Object.keys(fields_errors.booking_page).length ? fields_errors : this.throttleVerifySpecialDates(values);
  };

  onSubmit = (values) => {
    $("#booking_page_settings_form").submit()
  };

  render() {
    return (
      <Form
        initialValues={{ booking_page: { ...transformValues(this.props.booking_page) }}}
        onSubmit={this.onSubmit}
        validate={this.validate}
        decorators={[this.focusOnError, this.calculator]}
        mutators={{
          ...arrayMutators,
        }}
        render={({ handleSubmit, submitting, values, form }) => {
          this.booking_page_settings_form = form;
          this.booking_page_settings_values = values;

          return (
            <form
              action={this.props.path.save}
              className="booking-page-settings settings-form"
              id="booking_page_settings_form"
              onSubmit={handleSubmit}
              acceptCharset="UTF-8"
              method="post">
              <input name="utf8" type="hidden" value="✓" />
              {this.props.booking_page.id ? <input type="hidden" name="_method" value="PUT" /> : null}
              <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />

              {this.renderNameFields()}
              {this.renderShopFields()}
              {this.renderBookingOptionFields()}
              {this.renderBookingDateFields(values)}
              {this.renderBookingIntervalFields()}
              {this.renderBookingPeriodFields()}
              {this.renderBookingOverlapRestrictionField()}
              {this.renderBookingNoteField()}

              <ul id="footerav">
                <li>
                  <a className="BTNtarco" href={this.props.path.cancel}>{this.props.i18n.cancel}</a>
                </li>
                <li>
                  <input
                    type="submit"
                    name="commit"
                    value={this.props.i18n.save}
                    className="BTNyellow"
                    data-disable-with={this.props.i18n.save}
                    disabled={submitting}
                  />
                </li>
              </ul>
            </form>
          )
        }}
      />
    )
  }

  initAvailableBookingOptions = async () => {
    const options = await this.fetchAvailableBookingOptions(this.booking_page_settings_values);

    this.booking_page_settings_form.change("booking_page[available_booking_options]", options["booking_page[available_booking_options]"])
  }

  fetchAvailableBookingOptions = async (allValues) => {
    const { shop_id } = allValues.booking_page;

    if (this.fetchAvailableBookingOptionsCall) {
      this.fetchAvailableBookingOptionsCall.cancel();
    }
    this.fetchAvailableBookingOptionsCall= axios.CancelToken.source();

    if (!shop_id) {
      return {
        "booking_page[available_booking_options]": []
      }
    }

    const response = await axios({
      method: "GET",
      url: this.props.path.booking_options,
      params: {
        shop_id: shop_id
      },
      responseType: "json",
      cancelToken: this.fetchAvailableBookingOptionsCall.token
    })

    return {
      "booking_page[available_booking_options]": response.data.available_booking_options
    }
  }
}

export default BookingPageSettings;
