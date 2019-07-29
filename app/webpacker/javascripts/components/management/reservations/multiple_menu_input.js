import React from "react";
import { Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays';
import ReactSelect from "react-select";
import { OnChange } from 'react-final-form-listeners'
import _ from "lodash";

import { selectCustomStyles } from "../../../libraries/styles";
import { InputRow } from "../../shared/components";
import { displayErrors } from "./helpers.js"

const MenuStaffsFields = ({ all_values, fields, menu_field_name, staff_options, i18n, is_editable }) => {
  let selected_ids = []
  const {
    responsible_employee,
  } = i18n;

  return (
    <div>
      {fields.map((staff_field, index) => {
        const selected_id = _.get(all_values, `${staff_field}staff_id`)
        const menu = _.get(all_values, menu_field_name)

        const filterd_staff_options = staff_options.filter((staff_option) => !selected_ids.includes(String(staff_option.value)))

        if (selected_id) {
          selected_ids.push(selected_id)
        }

        return (
          <div key={`menu_field_${index}`}>
            <Field
              name={`${staff_field}staff_id`}
              component="select"
              disabled={!is_editable}
              className="staff-selection-field"
            >
              <option value="">
                {i18n.select_a_staff}
              </option>
              {filterd_staff_options.map((staff_option) => (
                <option value={staff_option.value} key={staff_option.value}>
                  {staff_option.label}
                </option>
              ))}
            </Field>

            <Field
              name={`${staff_field}state`}
              type="hidden"
              component="input"
            />
            {
              !is_editable || (!menu || index < Math.max(menu.min_staffs_number, 1)) ? null : (
                <a
                  href="#"
                  className="btn btn-symbol btn-orange after-field-btn"
                  onClick={(event) => {
                    if (!is_editable) return;
                    event.preventDefault();
                    fields.remove(index)
                  }
                  }>
                  <i className="fa fa-minus" aria-hidden="true" ></i>
                </a>
              )
            }
            <span className="errors">
              {displayErrors(all_values.reservation_form, [`${staff_field}[staff_id]`])}
            </span>
          </div>
        )
      })}
      <a
        className={`btn btn-yellow btn-add-staff ${staff_options.length === fields.length || !is_editable ? "disabled" : ""}`}
        onClick={(event) => {
          event.preventDefault();
          if (!is_editable) return;
          if (staff_options.length  === fields.length) return;

          fields.push({
            staff_id: null,
            state: "pending"
          })
        }}>
        <i className="fa fa-plus" aria-hidden="true"></i>{responsible_employee}
      </a>
    </div>
  )
}

const MenuFields = ({ reservation_form, all_values, collection_name, fields, field, menu_index, staff_options, menu_options, i18n, is_editable }) => {
  const {
    select_a_menu,
    required_time,
    menu,
    responsible_employee,
  } = i18n;

  return (
    <div className="result-field">
      <dl className="menu-field-row">
        <dt className="menu-field-label">
          {menu}
        </dt>
        <dd className="menu-field-content">
          <Field
            name={`${field}menu`}
            render={({ input }) => {
              return (
                <ReactSelect
                  ref={(c) => this.menuSelector = c}
                  className="menu-select-container"
                  styles={selectCustomStyles}
                  placeholder={select_a_menu}
                  options={menu_options}
                  defaultValue={input.value}
                  onChange={(event) => {
                    input.onChange(event);
                  }}
                  isDisabled={!is_editable}
                />
              )
            }}
          />
          <OnChange name={`${field}menu`}>
            {(option) => {
              reservation_form.change(`${field}menu_id`, option.value)
              reservation_form.change(`${field}menu_required_time`, option.minutes)
              reservation_form.change(`${field}menu_interval_time`, option.interval)

              const staff_ids = [];
              for (let i = 0; i < Math.max(option.min_staffs_number, 1); i++) {
                staff_ids.push({
                  staff_id: null,
                  state: "pending"
                });
              }
              reservation_form.change(`${field}staff_ids`, staff_ids)
            }}
          </OnChange>
          <span className="errors">
            {displayErrors(all_values.reservation_form, [`${field}[menu_id]`])}
          </span>
        </dd>
      </dl>
      <dl className="menu-field-row">
        <dt className="menu-field-label">
          {required_time}
        </dt>
        <dd className="menu-field-content">
          <Field
            name={`${field}menu_required_time`}
            type="number"
            component={InputRow}
            placeholder={required_time}
            disabled={!is_editable}
          />
        </dd>
      </dl>
      <dl className="menu-field-row">
        <dt className="menu-field-label">
          {responsible_employee}
        </dt>
        <dd className="menu-field-content">
          <FieldArray
            name={`${field}staff_ids`}
            menu_field_name={`${field}menu`}
            component={MenuStaffsFields}
            staff_options={staff_options}
            all_values={all_values}
            i18n={i18n}
            is_editable={is_editable}
          />
        </dd>
      </dl>
      <div className="menu-options-actions">
        <a
          href="#"
          className={`btn btn-orange ${is_editable ? "" : "disabled"}`}
          onClick={(event) => {
            if (!is_editable) return;
            event.preventDefault();

            fields.remove(menu_index)
          }
          }>
          {i18n.delete}
        </a>
        <a
          href="#"
          className="btn btn-yellow"
          data-action="click->collapse#close">
          OK
        </a>
      </div>

      <Field
        name={`${field}menu_id`}
        type="hidden"
        component="input"
      />
      <Field
        name={`${field}menu_interval_time`}
        type="hidden"
        component="input"
      />
    </div>
  )
}

const MenuRows = ({ fields, collection_name, all_values, staff_options, i18n, ...rest }) => {
  const {
    select_a_menu,
    minute,
  } = i18n;
  const default_menu_collapse_status = fields && fields.length > 1 ? "closed" : "open"

  return (
    <div>
      {fields.map((menu_field, index) => {
        const menu = _.get(all_values, `${menu_field}menu`)
        const menu_required_time = _.get(all_values, `${menu_field}menu_required_time`)
        let staff_ids = []
        if (_.get(all_values, `${menu_field}staff_ids`)) {
          staff_ids = _.get(all_values, `${menu_field}staff_ids`).map((staff) => staff.staff_id)
        }
        const staff_names = staff_options.filter((staff_option) => staff_ids.includes(String(staff_option.value))).map((staff_option) => staff_option.label).join(", ")

        return (
          <div
            key={`${collection_name}-${index}`}
            className="menu-option-field"
            data-controller="collapse"
            data-collapse-status={default_menu_collapse_status}>
            <div
              className="menu-option-header"
              data-action="click->collapse#toggle">
              <span className="menu-with-staffs">
                <span className="menu-option-info-name">
                  {menu ? menu.label : select_a_menu}
                </span>
                <span className="menu-option-info-staffs-name">
                  {staff_names}
                </span>
              </span>
              <span className="menu-option-info-required-time">
                {menu_required_time}{minute}
                <span className="menu-option-details-toggler">
                  <a className="toggler-link" data-target="collapse.openToggler"><i className="fa fa-chevron-up" aria-hidden="true"></i></a>
                  <a className="toggler-link" data-target="collapse.closeToggler"><i className="fa fa-chevron-down" aria-hidden="true"></i></a>
                </span>
              </span>
            </div>
            <div className="menu-option-content" data-target="collapse.content">
              <MenuFields
                all_values={all_values}
                staff_options={staff_options}
                fields={fields}
                field={menu_field}
                menu_index={index}
                i18n={i18n}
                {...rest}
              />
            </div>
          </div>
        )
      })}
    </div>
  )
}

const MultipleMenuFields = ({ fields, is_editable, i18n, ...rest }) => {
  const {
    add_a_menu
  } = i18n;

  return (
    <div>
      <MenuRows
        fields={fields}
        is_editable={is_editable}
        i18n={i18n}
        {...rest}
      />
      {is_editable && (
        <div className="centerize add-menu">
          <a
            className="btn btn-yellow after-field-btn"
            onClick={(event) => {
              event.preventDefault();

              fields.push({
                menu_id: null,
                position: fields.length,
                menu_required_time: null,
                menu_interval_time: null,
                staff_ids: [{
                  staff_id: null,
                  state: "pending"
                }]
              })

              // Open the new menu collapse by default
              setTimeout(() => {
                $(".menu-option-header").last().click()
              }, 0)
            }}>
            <i className="fa fa-plus" aria-hidden="true" ></i>
            {add_a_menu}
          </a>
        </div>
      )}
    </div>
  )
}

const MultipleMenuInput = ({ reservation_form, all_values, collection_name, staff_options, menu_options, i18n, is_editable }) => {
  return (
    <FieldArray
      name={collection_name}
      component={MultipleMenuFields}
      collection_name={collection_name}
      reservation_form={reservation_form}
      all_values={all_values}
      staff_options={staff_options}
      menu_options={menu_options}
      i18n={i18n}
      is_editable={is_editable}
    />
  );
}

export default MultipleMenuInput;
