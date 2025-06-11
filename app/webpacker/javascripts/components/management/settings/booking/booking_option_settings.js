"use strict";

import React from "react";
import { Form, Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import createFocusDecorator from "final-form-focus";
import createChangesDecorator from "final-form-calculate";
import arrayMutators from 'final-form-arrays'
import { sortableContainer, sortableElement } from "react-sortable-hoc";
import arrayMove from "array-move";
import moment from "moment-timezone";
import _ from "lodash";

import { mustBeNumber, requiredValidation, greaterEqualThan, transformValues, composeValidators } from "../../../../libraries/helper";
import { Input, InputRow, Radio, Error, Condition } from "shared/components";
import CommonDatepickerField from "shared/datepicker_field";
import DateFieldAdapter from "shared/date_field_adapter";
import SelectMultipleInputs from "shared/select_multiple_inputs";
import { DragHandle } from "shared/components";

class BookingOptionSettings extends React.Component {
  constructor(props) {
    super(props);
    this.focusOnError = createFocusDecorator();
    this.calculator = createChangesDecorator({
      field: /booking_option\[menus\]/,
      updates: (value, name, allValues) => {
        return this.booking_option_times_calculation(allValues)
      }
    })
  };

  booking_option_times_calculation = (allValues) => {
    return {
      "booking_option[minutes]": (allValues.booking_option.menus || []).reduce((sum, menu) => sum + Number(menu.required_time || 0), 0)
    }
  }

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
            validate={(value) => requiredValidation(price_name)(this, value)}
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

  onSortEnd = ({oldIndex, newIndex}) => {
    const sorted_menus = arrayMove(this.booking_option_settings_form_values.menus, oldIndex, newIndex).map((menu, i) => {
      menu.priority = i
      return menu
    })

    this.booking_option_settings_form.change("booking_option[menus]", sorted_menus)
  };

  renderSelectedMenuFields = (fields, _) => {
    return <SortableOptionsList
      useDragHandle
      onSortEnd={this.onSortEnd}
      menu_values={this.booking_option_settings_form_values.menus}
      fields={fields}
      i18n={this.props.i18n}
    />
  };

  renderMenuFields = () => {
    const {
      menu_for_sale_label,
      select_a_menu,
      menu_restrict_dont_need_order,
      menu_restrict_order,
    } = this.props.i18n;

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
          <dl>
            <dt>
              <div className="radio">
                <Field name="booking_option[menu_restrict_order]" type="radio" value="false" component={Radio}>
                  {menu_restrict_dont_need_order}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[menu_restrict_order]" type="radio" value="true" component={Radio}>
                  {menu_restrict_order}
                </Field>
              </div>
            </dt>
          </dl>
        </div>
      </div>
    );
  };

  renderTimeFields = () => {
    const { required_label, time_span_label, menu_time_span, total, minute, total_time } = this.props.i18n;

    return (
      <div>
        <h3>{time_span_label}<strong>{required_label}</strong></h3>
        <div className="formRow">
          <dl>
            <dt>
              {menu_time_span}
            </dt>
            <FieldArray name="booking_option[menus]">
              {({ fields }) => (
                <div>
                  {fields.map((field, index) => (
                    <div key={`menu-${index}`} className="result-field">
                      <Field name={`${field}label`}>
                        {({input, meta}) => (
                          <span className="before-field-hint">
                            {input.value}
                          </span>
                        )}
                      </Field>
                      <Field
                        name={`${field}required_time`}
                        type="number"
                        component={Input}
                        validate={
                          composeValidators(
                            this,
                            requiredValidation(menu_time_span),
                            mustBeNumber,
                            greaterEqualThan(
                              this.booking_option_settings_form_values.menus[index] && this.booking_option_settings_form_values.menus[index].minutes || 0,
                              menu_time_span)
                          )
                        }
                      />
                      <span className="field-hint">
                        {minute}
                      </span>
                      <Error name={`${field}required_time`} />
                    </div>
                  ))}
                </div>
              )}
            </FieldArray>
          </dl>
          <Field
            name="booking_option[minutes]"
            label={total_time}
            type="number"
            component={InputRow}
            before_hint={total}
            hint={minute}
            readOnly={true}
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
            validate={(value) => requiredValidation(price)(this, value)}
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

  renderOptionTypeFields = () => {
    const { option_type_setting_header, option_type, primary_option, secondary_option, option_type_hint } = this.props.i18n;

    return (
      <div>
        <h3>{option_type_setting_header}</h3>
        <div className="formRow">
          <dl>
            <dt>{option_type}</dt>
            <dd>
              <div className="radio">
                <Field name="booking_option[option_type]" type="radio" value="primary" component={Radio}>
                  {primary_option}
                </Field>
              </div>
              <div className="radio">
                <Field name="booking_option[option_type]" type="radio" value="secondary" component={Radio}>
                  {secondary_option}
                </Field>
              </div>
              <div className="hint">{option_type_hint}</div>
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
          <Field
            name="booking_option[memo]"
            component={InputRow}
            componentType="textarea"
            placeholder={note_hint}
            cols={100}
            rows={10}
          />
        </div>
      </div>
    );
  };

  validate = (values) => {
    const fields_errors = {};
    fields_errors.booking_option = {};
    const { menus, minutes, tax_include, start_at_type, start_at_time_part, end_at_type, end_at_time_part } = values.booking_option || {};
    const {
      errors,
      form_errors,
      menu_for_sale_label,
      tax_label,
      sale_start,
      sale_end,
    } = this.props.i18n;

    if (!tax_include) {
      fields_errors.booking_option.tax_include = `${tax_label}${errors.required}`;
    }

    if (start_at_type === "date" && !start_at_time_part) {
      fields_errors.booking_option.start_at_time_part = `${sale_start}${errors.required}`;
    }

    if (end_at_type === "date" && !end_at_time_part) {
      fields_errors.booking_option.end_at_time_part = `${sale_end}${errors.required}`;
    }

    if (!menus.length) {
      fields_errors.selected_menu = `${menu_for_sale_label}${errors.required}`;
    }

    if (menus.length > this.props.menu_total_limit) {
      fields_errors.selected_menu = `${menu_for_sale_label}${form_errors.reached_the_menus_limit}`;
    }

    if (minutes === undefined) {
      fields_errors.booking_option.minutes = errors.required;
    } else if (minutes < _.min(menus.map((menu) => menu.minutes))) {
      fields_errors.booking_option.minutes = form_errors.enough_time_for_menu;
    }

    return fields_errors;
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
        render={({ handleSubmit, submitting, form, values }) => {
          this.booking_option_settings_form = form;
          this.booking_option_settings_form_values = values.booking_option;

          return (
            <form
              action={this.props.path.save}
              className="booking-option-settings settings-form"
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
              {this.renderOptionTypeFields()}
              {this.renderMemoFields()}

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
}

const SortableMenuOption = sortableElement(({fields, field, i18n, index}) => {
  const { menu_time_span, minute } = i18n;

  return (
    <div className="result-field">
      <DragHandle />
      <Field
        name={`${field}label`}
        value={field.label}
        component="input"
        readOnly={true}
      />
      <Field
        name={`${field}priority`}
        value={field.priority}
        component="input"
        type="hidden"
      />
      <Field
        name={`${field}value`}
        value={field.value}
        component="input"
        type="hidden"
      />
      <a
        href="#"
        className="btn btn-symbol btn-orange after-field-btn"
        onClick={(event) => {
          event.preventDefault();
          fields.remove(index)
        }
        }
      >
        <i className="fa fa-minus" aria-hidden="true" ></i>
      </a>
      <Field name={`${field}minutes`} value={field.minutes}>
        {({input}) => <span className="field-hint">{menu_time_span}{input.value}{minute}</span>}
      </Field>
    </div>
  )
});

const SortableOptionsList = sortableContainer(({menu_values, fields, i18n}) => {
  return (
    <div className="result-fields">
      {fields.map((field, index) => {
        if (!menu_values[index]) { return; }

        return <SortableMenuOption
          key={`option-${menu_values[index].value}`}
          fields={fields}
          field={field}
          index={index}
          i18n={i18n}
        />
      })}
    </div>
  )
})

export default BookingOptionSettings;
