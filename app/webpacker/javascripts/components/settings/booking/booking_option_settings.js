"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import createFocusDecorator from "final-form-focus";
import createChangesDecorator from "final-form-calculate";
import arrayMutators from 'final-form-arrays'
import moment from "moment-timezone";

import { requiredValidation, transformValues } from "../../../libraries/helper";
import { InputRow, Radio, Error, Condition } from "../../shared/components";
import CommonDatepickerField from "../../shared/datepicker_field";
import DateFieldAdapter from "../../shared/date_field_adapter";
import SelectMultipleInputs from "../../shared/select_multiple_inputs";

class BookingOptionSettings extends React.Component {
  constructor(props) {
    super(props);
    this.focusOnError = createFocusDecorator();
    this.calculator = createChangesDecorator({
      field: /booking_option\[menus\]/, // when a field matching this pattern changes...
      updates: {
        "booking_option[minutes]": (menuValues, allValues) => {
          return (allValues.booking_option.menus || []).reduce((sum, menu) => sum + Number(menu.minutes || 0), 0)
        },
        "booking_option[interval]": (menuValues, allValues) => (allValues.booking_option.menus || []).reduce((sum, menu) => sum + Number(menu.interval || 0), 0)
      }
    })
  };


  renderNameFields = () => {
    const { required_label, price_name, price_name_hint, display_name, display_name_hint } = this.props.i18n;

    return (
      <div>
        <h3>{price_name}</h3>
        <div className="formRow">
          <Field
            name="booking_option[name]"
            component={InputRow}
            type="text"
            validate={(value) => requiredValidation(this, value)}
            label={price_name}
            placeholder={price_name}
            hint={price_name_hint}
            requiredLabel={required_label}
          />

          <Field
            name="booking_option[display_name]"
            component={InputRow}
            type="text"
            label={display_name}
            placeholder={display_name}
            hint={display_name_hint}
          />
        </div>
      </div>
    );
  }

  renderSelectedMenuFields = (fields, collection_name) => {
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
             <Field
               name={`${field}minutes`}
               value={field.minutes}
               component={({input}) => <span className="field-hint">{menu_time_span}{input.value}{minute}</span>}
             />
             <Field
               name={`${field}interval`}
               value={field.interval}
               component={({input}) => <span className="field-hint">{menu_interval}{input.value}{minute}</span>}
             />
           </div>
          )
         })}
      </div>
    )
  };

  renderMenuFields = () => {
    const { menu_for_sale_label, select_a_menu } = this.props.i18n;

    return (
      <div>
        <h3>{menu_for_sale_label}</h3>
        <div className="formRow">
          <dl>
            <Field
              name="selected_menu"
              collection_name="booking_option[menus]"
              component={SelectMultipleInputs}
              resultFields={this.renderSelectedMenuFields}
              options={this.props.menu_group_options}
              selectLabel={select_a_menu}
              />
          </dl>
        </div>
      </div>
    );
  };

  renderTimeFields = () => {
    const { required_label, time_span_label, menu_time_span, menu_interval, total, minute, reservation_interval } = this.props.i18n;

    return (
      <div>
        <h3>{time_span_label}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <Field
            name="booking_option[minutes]"
            label={menu_time_span}
            type="number"
            validate={(value) => requiredValidation(this, value)}
            component={InputRow}
            before_hint={total}
            hint={minute}
          />
          <Field
            name="booking_option[interval]"
            label={menu_interval}
            type="number"
            validate={(value) => requiredValidation(this, value)}
            component={InputRow}
            before_hint={reservation_interval}
            hint={minute}
          />
        </div>
      </div>
    );
  };

  renderPriceFields = () => {
    const { required_label, price_label, price, currency_unit, tax_label, tax_include, tax_excluded } = this.props.i18n;

    return (
      <div>
        <h3>{price_label}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <Field
            name="booking_option[amount_cents]"
            label={price}
            type="number"
            validate={(value) => requiredValidation(this, value)}
            component={InputRow}
            hint={currency_unit}
          />
          <dl>
            <dt>{tax_label}</dt>
            <dd>
              <div className="radio">
                <Field name="booking_option[tax_include]" type="radio" value="true" component={Radio}>
                  {tax_include}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[tax_include]" type="radio" value="false" component={Radio}>
                  {tax_excluded}
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
    const { required_label, sale_period, sale_start, sale_end, sale_now, sale_on, sale_forever } = this.props.i18n;

    return (
      <div>
        <h3>{sale_period}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <dl>
            <dt>{sale_start}</dt>
            <dd>
              <div className="radio">
                <Field name="booking_option[start_at_type]" type="radio" value="now" component={Radio}>
                  {sale_now}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[start_at_type]" type="radio" value="date" component={Radio}>
                  {sale_on}
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
            <dt>{sale_end}</dt>
            <dd>
              <div className="radio">
                <Field name="booking_option[end_at_type]" type="radio" value="now" component={Radio}>
                  {sale_forever}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[end_at_type]" type="radio" value="date" component={Radio}>
                  {sale_on}
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
        </div>
      </div>
    );
  };

  renderMemoFields = () => {
    const { note_label, note_hint } = this.props.i18n;

    return (
      <div>
        <h3>{note_label}</h3>
        <div className="formRow">
          <dl>
            <dd>
              <Field
                name="booking_option[memo]"
                label={note_label}
                component="textarea"
                placeholder={note_hint}
                cols={100}
                rows={10}
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
    const { required } = this.props.i18n.errors;

    if (!tax_include) {
      errors.booking_option.tax_include = required;
    }

    if (start_at_type === "date" && !start_at_time_part) {
      errors.booking_option.start_at_time_part = required;
    }

    if (end_at_type === "date" && !end_at_time_part) {
      errors.booking_option.end_at_time_part = required;
    }

    if (!values.booking_option.menus.length) {
      errors.selected_menu = required;
    }

    return errors;
  };

  onSubmit = (values) => {
    $("#booking_option_settings_form").submit()
  };

  render() {
    return (
      <Form
        initialValues={{ booking_option: { ...transformValues(this.props.booking_option) }}}
        onSubmit={this.onSubmit}
        validate={this.validate}
        decorators={[this.focusOnError, this.calculator]}
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
            {this.props.booking_option.id ? <input type="hidden" name="_method" value="PUT" /> : null}
            <input type="hidden" name="authenticity_token" value={this.props.form_authenticity_token} />

            {this.renderNameFields()}
            {this.renderMenuFields()}
            {this.renderTimeFields()}
            {this.renderPriceFields()}
            {this.renderSellingTimeFields()}
            {this.renderMemoFields()}

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

export default BookingOptionSettings;
