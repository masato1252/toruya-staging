"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import createDecorator from "final-form-focus";

import { requiredValidation, transformValues } from "../../../libraries/helper";
import { InputRow, Radio, Error } from "../../shared/components";

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
          <input
            type="hidden"
            name="booking_option[amount_currency]"
            value="JPY"
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
        </div>
      </div>
    );
  };

  renderSellingTimeFields = () => {

  };

  renderMemoFields = () => {

  };

  validate = (values) => {
    const errors = {};
    errors.booking_option = {};
    const { tax_include } = values.booking_option || {};

    if (!tax_include) {
      errors.booking_option.tax_include = this.props.i18n.errors.required;
    }

    return errors;
  };

  onSubmit = (values) => {
    console.log(values)
    $("#booking_option_settings_form").submit()
    // document.getElementById('booking_option_settings_form').dispatchEvent(new Event('submit', { cancelable: true }))
  };

  render() {
    return (
      <Form
        initialValues={{ booking_option: { ...transformValues(this.props.bookingOption) }}}
        onSubmit={this.onSubmit}
        validate={this.validate}
        decorators={[this.focusOnError]}
        render={({ handleSubmit, submitting, invalid }) => (
          <form onSubmit={handleSubmit}
            className="booking_option_settings"
            id="booking_option_settings_form"
            action={this.props.path.save} acceptCharset="UTF-8" method="post">
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

  _isValid = () => {
    return true
  };

}

export default BookingOptionSettings;
