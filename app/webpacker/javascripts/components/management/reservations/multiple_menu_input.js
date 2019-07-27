import React from "react";
import { Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays';
import ReactSelect from "react-select";
import { OnChange } from 'react-final-form-listeners'
import _ from "lodash";

import { selectCustomStyles } from "../../../libraries/styles";
import { InputRow } from "../../shared/components";
import { displayErrors } from "./helpers.js"

const MenuStaffsFields = ({ all_values, fields, menu_field_name, staff_options, i18n }) => {
  let selected_ids = []

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
              (!menu || index < Math.max(menu.min_staffs_number, 1)) ? null : (
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
              )
            }
            <span className="errors">
              {displayErrors(all_values.reservation_form, [`${staff_field}[staff_id]`])}
            </span>
          </div>
        )
      })}
      <a
        className={`btn btn-yellow ${staff_options.length === fields.length ? "disabled" : ""}`}
        onClick={(event) => {
          event.preventDefault();
          if (staff_options.length  === fields.length) return;

          fields.push({
            staff_id: null,
            state: "pending"
          })
        }}>
        Add Staff
      </a>
    </div>
  )
}

const MenusFields = ({ reservation_form, all_values, collection_name, fields, staff_options, menu_options, i18n }) => {
  const {
    select_a_menu,
  } = i18n;

  return (
    <div>
      {fields.map((field, index) => {
        return (
          <div key={`${collection_name}-${index}`} className="result-field">
            <div>
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
            </div>
            <div>
              <Field
                name={`${field}menu_required_time`}
                type="number"
                component={InputRow}
              />
            </div>
            <FieldArray
              name={`${field}staff_ids`}
              menu_field_name={`${field}menu`}
              component={MenuStaffsFields}
              staff_options={staff_options}
              all_values={all_values}
              i18n={i18n}
            />
            <div className="menu-options-actions">
              <a
                href="#"
                className="btn btn-orange"
                onClick={(event) => {
                  event.preventDefault();
                  fields.remove(index)
                }
                }>
                DELETE MENU
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
      })}
    </div>
  )
}

const MultipleMenuFields = ({ fields, ...rest }) => {
  return (
    <div>
      <MenusFields
        fields={fields}
        {...rest}
      />
      <div className="centerize">
        <a
          className="btn btn-symbol btn-yellow after-field-btn"
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
          }}>
          <i className="fa fa-plus" aria-hidden="true" ></i>
        </a>
      </div>
    </div>
  )
}

const MultipleMenuInput = ({ reservation_form, all_values, collection_name, staff_options, menu_options, i18n }) => {
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
    />
  );
}

export default MultipleMenuInput;
