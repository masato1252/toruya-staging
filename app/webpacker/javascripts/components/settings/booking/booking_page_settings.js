"use strict";

import React from "react";
import { Form, Field, FormSpy } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import createFocusDecorator from "final-form-focus";
import createChangesDecorator from "final-form-calculate";
import arrayMutators from 'final-form-arrays'
import moment from "moment-timezone";
import _ from "lodash";

import { requiredValidation, transformValues } from "../../../libraries/helper";
import { InputRow, RadioRow, Radio, Error, Condition } from "../../shared/components";
import CommonDatepickerField from "../../shared/datepicker_field";
import DateFieldAdapter from "../../shared/date_field_adapter";
import SelectMultipleInputs from "../../shared/select_multiple_inputs";

class BookingPageSettings extends React.Component {
  constructor(props) {
    super(props);
    this.focusOnError = createFocusDecorator();
    this.calculator = createChangesDecorator({
      field: /booking_page\[booking_options\]/, // when a field matching this pattern changes...
      updates: {
        "booking_page[interval]": (menuValues, allValues) => (allValues.booking_option.menus || []).reduce((sum, menu) => sum + Number(menu.interval || 0), 0)
      }
    })
  };


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
            validate={(value) => requiredValidation(this, value)}
            label={page_name}
            hint={page_name_hint}
            requiredLabel={required_label}
          />

          <Field
            name="booking_page[title]"
            component={InputRow}
            type="text"
            label={title}
            hint={title_hint}
          />

          <Field
            name="booking_page[greeting]"
            component={InputRow}
            componentType="textarea"
            label={greeting}
            placeholder={greeting_placeholder}
            cols={100}
            rows={10}
          />
        </div>
      </div>
    );
  }

  renderSelectedBookingOptionFields = (fields, collection_name) => {
    const { menu_time_span, menu_interval, minute } = this.props.i18n;

    return (
      <div className="result-fields">
        {fields.map((field, index) => {
          return (
           <div key={`${collection_name}-${index}`} className="result-field">
             <Field
               name={`${field}label`}
               value={field.label}
               component="input"
               readOnly={true}
             />
             <Field
               name={`${field}value`}
               value={field.value}
               component="input"
               type="hidden"
             />
             <a
               href="#"
               className="btn btn-symbol btn-orange"
               onClick={() => {fields.remove(index) }}
               >
               <i className="fa fa-minus" aria-hidden="true" ></i>
             </a>
           </div>
          )
         })}
      </div>
    )
  };

  renderBookingOptionFields = () => {
    const { required_label, booking_option_header, select_a_booking_option, booking_option_hint } = this.props.i18n;

    return (
      <div>
        <h3>{booking_option_header}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <dl>
            <Field
              name="selected_booking_option"
              collection_name="booking_page[options]"
              component={SelectMultipleInputs}
              resultFields={this.renderSelectedBookingOptionFields}
              options={this.props.booking_options}
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
      </div>
    );
  }

  resultFields = (fields, collection_name) => {
    return (
      <div className="result-fields">
        {fields.map((field, index) => {
          return (
           <div key={`${collection_name}-${index}`} className="result-field">
              <Field
                name={`${field}start_at_date_part`}
                component={DateFieldAdapter}
                date={moment().format("YYYY-MM-DD")}
                hiddenWeekDate={true}
              />
              <Field
                name={`${field}start_at_time_part`}
                type="time"
                component="input"
              />
              <Field
                name={`${field}end_at_date_part`}
                type="hidden"
                component="input"
              />
              <Field
                name={`${field}end_at_time_part`}
                type="time"
                component="input"
              />
             <a
               href="#"
               className="btn btn-symbol btn-orange after-field-btn"
               onClick={(event) => {
                   event.preventDefault();
                   fields.remove(index)
                 }
               }>
               <i className="fa fa-minus" aria-hidden="true" ></i>
             </a>
           </div>
          )
         })}
      </div>
    );
  };

  renderBookingDateFields = () => {
    const { required_label, booking_dates_header } = this.props.i18n;

    const collection_name = "booking_page[special_dates]"

    return (
      <div>
        <h3>{booking_dates_header}</h3>
        <div className="formRow">
          <FieldArray name={collection_name}>
            {({ fields }) => (
              <div className="select-multiple-inputs">
                {this.resultFields(fields, collection_name)}
                <Field
                  name="start_at_date_part"
                  component={DateFieldAdapter}
                  date={moment().format("YYYY-MM-DD")}
                  hiddenWeekDate={true}
                />
                <Field
                  name="start_at_time_part"
                  type="time"
                  component="input"
                />
                <Field
                  name="end_at_date_part"
                  type="hidden"
                  component="input"
                />
                <Field
                  name="end_at_time_part"
                  type="time"
                  component="input"
                />
                <FormSpy subscription={{ values: true }}>
                  {({ values }) => (
                      <a
                        href="#"
                        className={`btn btn-symbol btn-yellow after-field-btn`}
                        onClick={(event) => {
                          event.preventDefault();

                          const start_at_date_part = values.start_at_date_part || moment().format("YYYY-MM-DD");
                          fields.push({
                            start_at_date_part: start_at_date_part,
                            start_at_time_part: values.start_at_time_part,
                            end_at_date_part: start_at_date_part,
                            end_at_time_part: values.end_at_time_part
                          })
                        }}>
                        <i className="fa fa-plus" aria-hidden="true" ></i>
                      </a>
                  )}
                </FormSpy>
              </div>
            )}
          </FieldArray>
        </div>
      </div>
    );
  }

  renderBookingIntervalFields = () => {
    const { required_label, interval_header } = this.props.i18n;

    return (
      <div>
        <h3>{interval_header}</h3>
        <div className="formRow">
          <Field
            name="booking_page[interval]"
            component={InputRow}
            type="number"
            requiredLabel={required_label}
          />
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
                    date={moment().format("YYYY-MM-DD")}
                    hiddenWeekDate={true}
                  />
                  <Field
                    name="booking_page[start_at_time_part]"
                    type="time"
                    component="input"
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
                    date={moment().format("YYYY-MM-DD")}
                    hiddenWeekDate={true}
                  />
                  <Field
                    name="booking_page[end_at_time_part]"
                    type="time"
                    component="input"
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

  renderBookingNoteField = () => {
    const { note_label, note_hint } = this.props.i18n;

    return (
      <div>
        <h3>{note_label}</h3>
        <div className="formRow">
          <Field
            name="booking_page[note]"
            component={InputRow}
            componentType="textarea"
            placeholder={note_label}
            cols={100}
            rows={10}
          />
        </div>
      </div>
    );
  }

  validate = (values) => {
    console.log(values);
    const fields_errors = {};
    fields_errors.booking_page = {};

    return fields_errors;
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
          ...arrayMutators
        }}
        render={({ handleSubmit, submitting }) => (
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
            {this.renderBookingOptionFields()}
            {this.renderShopFields()}
            {this.renderBookingDateFields()}
            {this.renderBookingIntervalFields()}
            {this.renderBookingPeriodFields()}
            {this.renderBookingNoteField()}

            <ul id="footerav">
              <li>
                <a className="BTNtarco" href={this.props.path.cancel}>{this.props.i18n.cancel_btn}</a>
              </li>
              <li>
                <input
                  type="submit"
                  name="commit"
                  value="保存"
                  className="BTNyellow"
                  data-disable-with="保存"
                  disabled={submitting}
                />
              </li>
            </ul>
          </form>
        )}
      />
    )
  }
}

export default BookingPageSettings;
