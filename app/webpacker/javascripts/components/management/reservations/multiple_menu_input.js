import React from "react";
import { Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays';
import ReactSelect from "react-select";
import { sortableContainer, sortableElement } from "react-sortable-hoc";
import _ from "lodash";
import arrayMove from "array-move";

import { selectCustomStyles } from "../../../libraries/styles";
import { InputRow, DragHandle } from "../../shared/components";
import { displayErrors } from "./helpers.js"

const staff_time_warnings = ["freelancer", "unworking_staff"]

const MenuStaffsFields = ({ all_values, fields, menu_field_name, i18n, reservation_properties, ...rest }) => {
  const {
    responsible_employee,
    add_working_schedule,
  } = i18n;

  const {
    staff_options,
    is_editable,
    downgrade_from_premium,
  } = reservation_properties;

  const {
    by_staff_id,
  } = all_values.reservation_form

  let selected_ids = []

  return (
    <div>
      {fields.map((staff_field, index) => {
        const selected_id = _.get(all_values, `${staff_field}staff_id`)
        const menu = _.get(all_values, menu_field_name)
        let current_user_working_date_modal = false;
        const staff_warnings = _.get(all_values.reservation_form.warnings, `${staff_field}staff_id`)

        const filterd_staff_options = staff_options.filter((staff_option) => !selected_ids.includes(String(staff_option.value)))

        if (selected_id) {
          selected_ids.push(selected_id)
        }

        // XXX: Find current_user staff had freelancer, unworking_staff warnings
        if (by_staff_id && String(by_staff_id) === String(selected_id) && staff_warnings) {
          const staff_warning_types = Object.keys(staff_warnings)

          if (_.intersection(staff_warning_types, staff_time_warnings).length) {
            current_user_working_date_modal = true
          }
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
            {
              current_user_working_date_modal && (
                <a href="#" data-toggle="modal" data-target="#working-date-modal" className="BTNtarco">
                  {add_working_schedule}
                </a>
              )
            }
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
        <i className="fa fa-user-plus" aria-hidden="true"></i>{responsible_employee}
      </a>
      {
        downgrade_from_premium && (
          <a href="https://toruya.com/faq/48/" target="_blank">
            <i className="fa fa-question-circle" aria-hidden="true"></i>自分以外のスタッフが選択できなくなった場合
            </a>
        )
      }
    </div>
  )
}

const MenuFields = ({ reservation_form, all_values, collection_name, menu_fields, menu_field, menu_index, i18n, reservation_properties, ...rest }) => {
  const {
    select_a_menu,
    required_time,
    menu,
    responsible_employee,
    no_manpower_tip,
  } = i18n;

  const {
    staff_options,
    menu_group_options,
    is_editable,
  } = reservation_properties

  const selected_menu = _.get(all_values, `${menu_field}menu`)

  return (
    <div className="result-field">
      <dl className="menu-field-row">
        <dt className="menu-field-label">
          {menu}
        </dt>
        <dd className="menu-field-content">
          <Field
            name={`${menu_field}menu`}
            render={({ input }) => {
              return (
                <ReactSelect
                  ref={(c) => this.menuSelector = c}
                  className="menu-select-container"
                  styles={selectCustomStyles}
                  placeholder={select_a_menu}
                  options={menu_group_options}
                  value={input.value}
                  defaultValue={input.value}
                  onChange={(option) => {
                    input.onChange(option);

                    reservation_form.change(`${menu_field}menu_id`, option.value)
                    reservation_form.change(`${menu_field}menu_required_time`, option.minutes)
                    reservation_form.change(`${menu_field}menu_interval_time`, option.interval)

                    const staff_ids = [];
                    for (let i = 0; i < Math.max(option.min_staffs_number, 1); i++) {
                      staff_ids.push({
                        staff_id: null,
                        state: "pending"
                      });
                    }
                    reservation_form.change(`${menu_field}staff_ids`, staff_ids)
                  }}
                  isDisabled={!is_editable}
                />
              )
            }}
          />
          <span className="errors">
            {selected_menu && selected_menu.min_staffs_number === 0 ? <span className="warning">{no_manpower_tip}</span> : null}
            {displayErrors(all_values.reservation_form, [`${menu_field}[menu_id]`])}
          </span>
        </dd>
      </dl>
      <dl className="menu-field-row">
        <dt className="menu-field-label">
          {required_time}
        </dt>
        <dd className="menu-field-content">
          <Field
            name={`${menu_field}menu_required_time`}
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
            name={`${menu_field}staff_ids`}
            menu_field_name={`${menu_field}menu`}
            component={MenuStaffsFields}
            all_values={all_values}
            i18n={i18n}
            reservation_properties={reservation_properties}
            {...rest}
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

            menu_fields.remove(menu_index)
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
        name={`${menu_field}menu_id`}
        type="hidden"
        component="input"
      />
      <Field
        name={`${menu_field}menu_interval_time`}
        type="hidden"
        component="input"
      />
    </div>
  )
}

const SortableMenuRow = sortableElement(({ menu_fields, menu_field, collection_name, all_values, reservation_properties, i18n, index, ...rest }) => {
  const {
    select_a_menu,
    minute,
  } = i18n;

  const {
    staff_options
  } = reservation_properties

  const default_menu_collapse_status = menu_fields && menu_fields.length > 1 ? "closed" : "open"

  const menu = _.get(all_values, `${menu_field}menu`)
  const menu_required_time = _.get(all_values, `${menu_field}menu_required_time`)
  let staff_ids = []
  if (_.get(all_values, `${menu_field}staff_ids`)) {
    staff_ids = _.get(all_values, `${menu_field}staff_ids`).map((staff) => String(staff.staff_id))
  }
  const staff_names = staff_options.filter((staff_option) => staff_ids.includes(String(staff_option.value))).map((staff_option) => staff_option.label).join(", ")

  return (
    <div
      className="menu-option-field"
      data-controller="collapse"
      data-collapse-status={default_menu_collapse_status}>
      <div
        className="menu-option-header"
        data-action="click->collapse#toggle">
        <span className="menu-with-staffs">
          <DragHandle />
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
          reservation_properties={reservation_properties}
          menu_fields={menu_fields}
          menu_field={menu_field}
          menu_index={index}
          i18n={i18n}
          {...rest}
        />
      </div>
    </div>
  )
})

const MenuRows = sortableContainer(({ menu_fields, collection_name, all_values, ...rest }) => {
  return (
    <div>
      {menu_fields.map((menu_field, index) => {
        return (
          <SortableMenuRow
            key={`${collection_name}-${_.get(all_values, `${menu_field}_menu_id`)}-${index}`}
            menu_fields={menu_fields}
            menu_field={menu_field}
            index={index}
            all_values={all_values}
            {...rest}
          />
        )
      })}
    </div>
  )
})

const MultipleMenuFields = ({ fields, reservation_properties, i18n, all_values, reservation_form, ...rest }) => {
  const {
    add_a_menu
  } = i18n;

  const {
    is_editable
  } = reservation_properties;

  return (
    <div>
      <MenuRows
        menu_fields={fields}
        reservation_properties={reservation_properties}
        i18n={i18n}
        all_values={all_values}
        reservation_form={reservation_form}
        {...rest}
        useDragHandle
        onSortEnd={({oldIndex, newIndex}) => {
          const sorted_menu_staffs_list = arrayMove(all_values.reservation_form.menu_staffs_list, oldIndex, newIndex)
          reservation_form.change("reservation_form[menu_staffs_list]", sorted_menu_staffs_list)
        }}
      />
      {is_editable && (
        <div className="centerize add-menu">
          <a
            className="btn btn-yellow after-field-btn"
            onClick={(event) => {
              event.preventDefault();

              fields.push({
                menu_id: null,
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

const MultipleMenuInput = ({ collection_name, ...rest }) => {
  return (
    <FieldArray
      name={collection_name}
      component={MultipleMenuFields}
      {...rest}
    />
  );
}

export default MultipleMenuInput;
