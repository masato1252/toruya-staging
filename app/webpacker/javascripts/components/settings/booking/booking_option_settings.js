"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import createDecorator from "final-form-focus";
import arrayMutators from 'final-form-arrays'
import moment from "moment-timezone";

import { requiredValidation, transformValues, handleSingleAttrInput } from "../../../libraries/helper";
import { InputRow, Radio, Error, Condition } from "../../shared/components";
import CommonDatepickerField from "../../shared/datepicker_field";
import DateFieldAdapter from "../../shared/date_field_adapter";
import SelectMultipleInputs from "../../shared/select_multiple_inputs";

class BookingOptionSettings extends React.Component {
  constructor(props) {
    super(props);
    this.focusOnError = createDecorator();
  };

  renderNameFields = () => {
    return (
      <div>
        <h3>{this.props.i18n.infoLabel}</h3>
        <div className="formRow">
          <Field
            name="booking_option[name]"
            label="Name"
            type="text"
            requiredLabel={true}
            validate={(value) => requiredValidation(this, value)}
            component={InputRow}
          />

          <Field
            name="booking_option[display_name]"
            label="Display Name"
            type="text"
            component={InputRow}
            placeholder="display name"
          />
        </div>
      </div>
    );
  }

  renderMenuFields = () => {
    return (
      <div>
        <h3>{this.props.i18n.infoLabel}</h3>
        <div className="formRow">
          <Field
            name="menus"
            collection_name="menus"
            component={SelectMultipleInputs}
            options={this.props.menuGroupOptions}
          />
        </div>
      </div>
    );
  };

  renderTimeFields = () => {
    return (
      <div>
        <h3>{this.props.i18n.infoLabel}<strong>必須項目</strong></h3>
        <div className="formRow">
          <Field
            name="booking_option[minutes]"
            label="Minutes"
            type="number"
            validate={(value) => requiredValidation(this, value)}
            component={InputRow}
          />
          <Field
            name="booking_option[interval]"
            label="Interval"
            type="number"
            validate={(value) => requiredValidation(this, value)}
            component={InputRow}
          />
        </div>
      </div>
    );
  };

  renderPriceFields = () => {
    return (
      <div>
        <h3>{this.props.i18n.infoLabel}<strong>必須項目</strong></h3>
        <div className="formRow">
          <Field
            name="booking_option[amount_cents]"
            label="Price"
            type="number"
            validate={(value) => requiredValidation(this, value)}
            component={InputRow}
          />
          <dl>
            <dt>Tax Include</dt>
            <dd>
              <div className="radio">
                <Field name="booking_option[tax_include]" type="radio" value="true" component={Radio}>
                  Yes
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[tax_include]" type="radio" value="false" component={Radio}>
                  No
                </Field>
              </div>
              <Error name="booking_option[tax_include]" />
            </dd>
          </dl>
          <input
            type="hidden"
            name="booking_option[amount_currency]"
            value="JPY"
          />
        </div>
      </div>
    );
  };

  renderSellingTimeFields = () => {
    return (
      <div>
        <h3>{this.props.i18n.infoLabel}<strong>必須項目</strong></h3>
        <div className="formRow">
          <dl>
            <dt>Start At</dt>
            <dd>
              <div className="radio">
                <Field name="booking_option[start_at_type]" type="radio" value="now" component={Radio}>
                  Now
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[start_at_type]" type="radio" value="date" component={Radio}>
                  Specific date
                </Field>
              </div>
              <Condition when="booking_option[start_at_type]" is="date">
                <div>
                  <Field
                    name="booking_option[start_at_date_part]"
                    component={DateFieldAdapter}
                    date={moment().format("YYYY-MM-DD")}
                    hiddenWeekDate={true}
                  />
                  <Field
                    name="booking_option[start_at_time_part]"
                    type="time"
                    component="input"
                  />
                  <Error name="booking_option[start_at_time_part]" />
                </div>
              </Condition>
            </dd>
          </dl>
          <dl>
            <dt>End At</dt>
            <dd>
              <div className="radio">
                <Field name="booking_option[end_at_type]" type="radio" value="now" component={Radio}>
                  Now
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[end_at_type]" type="radio" value="date" component={Radio}>
                  Specific date
                </Field>
              </div>
              <Condition when="booking_option[end_at_type]" is="date">
                <div>
                  <Field
                    name="booking_option[end_at_date_part]"
                    component={DateFieldAdapter}
                    date={moment().format("YYYY-MM-DD")}
                    hiddenWeekDate={true}
                  />
                  <Field
                    name="booking_option[end_at_time_part]"
                    type="time"
                    component="input"
                  />
                  <Error name="booking_option[end_at_time_part]" />
                </div>
              </Condition>
            </dd>
          </dl>
          <input
            type="hidden"
            name="booking_option[amount_currency]"
            value="JPY"
          />
        </div>
      </div>
    );
  };

  renderMemoFields = () => {
    return (
      <div>
        <h3>{this.props.i18n.infoLabel}</h3>
        <div className="formRow">
          <dl>
            <dt>Memo</dt>
            <dd>
              <Field
                name="booking_option[memo]"
                label="Memo"
                component="textarea"
              />
            </dd>
          </dl>
        </div>
      </div>
    );
  };

  validate = (values) => {
    const errors = {};
    errors.booking_option = {};
    const { tax_include, start_at_type, start_at_time_part, end_at_type, end_at_time_part } = values.booking_option || {};

    if (!tax_include) {
      errors.booking_option.tax_include = this.props.i18n.errors.required;
    }

    if (start_at_type === "date" && !start_at_time_part) {
      errors.booking_option.start_at_time_part = this.props.i18n.errors.required;
    }

    if (end_at_type === "date" && !end_at_time_part) {
      errors.booking_option.end_at_time_part = this.props.i18n.errors.required;
    }

    return errors;
  };

  onSubmit = (values) => {
    $("#booking_option_settings_form").submit()
  };

  render() {
    return (
      <Form
        initialValues={{ menus: this.props.menus, booking_option: { ...transformValues(this.props.bookingOption) }}}
        onSubmit={this.onSubmit}
        validate={this.validate}
        decorators={[this.focusOnError]}
        mutators={{
          ...arrayMutators
        }}
        render={({ handleSubmit, submitting }) => (
          <form
            action={this.props.path.save}
            className="booking_option_settings"
            id="booking_option_settings_form"
            onSubmit={handleSubmit}
            acceptCharset="UTF-8"
            method="post">
            <input name="utf8" type="hidden" value="✓" />
            {this.props.bookingOption.id ? <input type="hidden" name="_method" value="PUT" /> : null}
            <input type="hidden" name="authenticity_token" value={this.props.formAuthenticityToken} />

            {this.renderNameFields()}
            {this.renderMenuFields()}
            {this.renderTimeFields()}
            {this.renderPriceFields()}
            {this.renderSellingTimeFields()}
            {this.renderMemoFields()}

            <ul id="footerav">
              <li>
                <a className="BTNtarco" href={this.props.path.cancel}>{this.props.i18n.cancelBtn}</a>
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

export default BookingOptionSettings;
