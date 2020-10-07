"use strict";

import React, { useEffect } from "react";
import ReactSelect from "react-select";
import { sortableContainer, sortableElement } from "react-sortable-hoc";

import { selectCustomStyles } from "libraries/styles";
import { displayErrors, arrayWithLength } from "libraries/helper";
import { DragHandle } from "shared/components";

const MenuOptionField = sortableElement(({menu_staffs_list, setMenuStaffsList, props, menu_staffs_fields, menu_index, reservation_errors}) => {
  return (
    <div
      className="menu-option-field"
      data-controller="collapse"
      data-collapse-status="open"
    >
      <div
        className="menu-option-header"
        data-action="click->collapse#toggle">
        <span className="menu-option-info-name">
          <DragHandle />
          {menu_staffs_fields.menu?.label || props.i18n.select_a_menu}
        </span>
        <span className="menu-option-details-toggler">
          {menu_staffs_fields.menu_required_time}{props.i18n.minute}
          <a className="toggler-link" data-target="collapse.openToggler"><i className="fa fa-chevron-up" aria-hidden="true"></i></a>
          <a className="toggler-link" data-target="collapse.closeToggler"><i className="fa fa-chevron-down" aria-hidden="true"></i></a>
        </span>
      </div>
      <div className="menu-option-content" data-target="collapse.content">
        <ReactSelect
          className="menu-select-container"
          styles={selectCustomStyles}
          placeholder={props.i18n.select_a_menu}
          value={menu_staffs_fields.menu}
          defaultValue={menu_staffs_fields.menu}
          options={props.reservation_properties.menu_group_options}
          onChange={(option) => {
            console.log(option)
            const data = [...menu_staffs_list];

            data[menu_index]["menu"] = option
            data[menu_index]["menu_id"] = option.value
            data[menu_index]["menu_required_time"] = option.minutes
            data[menu_index]["menu_interval_time"] = option.interval
            data[menu_index]["staff_ids"] = arrayWithLength(Math.max(option.min_staffs_number, 1), { staff_id: "" })

            setMenuStaffsList([...data])
          }}
          isDisabled={false}
        />
        {displayErrors(reservation_errors, [`reservation_form[menu_staffs_list][${menu_index}][menu_id]`])}
        <div className="menu-field-row">
          <div className="menu-field-label">{props.i18n.required_time}</div>
          <div className="menu-field-content">
            <input
              type="tel"
              placeholder={props.i18n.required_time}
              className="extend"
              value={menu_staffs_fields.menu_required_time || ""}
              onChange={((event) => {
                const data = [...menu_staffs_list];
                data[menu_index]["menu_required_time"] = event.target.value

                setMenuStaffsList([...data])
              })}
            />
          </div>
        </div>

        {menu_staffs_fields.staff_ids.map((staff_field, staff_index) => {
          return (
            <div key={`${menu_index}-${staff_index}`}>
              <select
                onChange={(event) => {
                  const data = [...menu_staffs_list];
                  data[menu_index]["staff_ids"][staff_index] = { staff_id: event.target.value }

                  setMenuStaffsList([...data])
                }}
                value={staff_field?.staff_id || ""}
              >
                <option value="" key="">{props.i18n.select_a_staff}</option>
                {props.reservation_properties.staff_options.map((staff_option) => (
                  <option
                    value={staff_option.value}
                    key={staff_option.value}>
                    {staff_option.label}
                  </option>
                ))}
              </select>
              <div
                className="delete-staff-block"
                onClick={() => {
                  const data = [...menu_staffs_list];
                  data[menu_index]["staff_ids"] = [
                    ...menu_staffs_list[menu_index]["staff_ids"].slice(0, staff_index),
                    ...menu_staffs_list[menu_index]["staff_ids"].slice(staff_index + 1)
                  ]

                  setMenuStaffsList([...data])
                }}>

                <button className="btn btn-orange">
                  <i className="fa fa-minus"></i>
                </button>
              </div>
              {displayErrors(reservation_errors, [`reservation_form[menu_staffs_list][${menu_index}]staff_ids[${staff_index}][staff_id]`])}
            </div>
          )
        })}

        <div>
          <div
            className="add-staff-block"
            onClick={() => {
              const data = [...menu_staffs_list];

              data[menu_index]["staff_ids"] = [...data[menu_index]["staff_ids"], {staff_id: null}]
              setMenuStaffsList([...data])
            }}>
            <button className="btn btn-yellow">
              <i className="fa fa-user-plus" aria-hidden="true"></i>{props.i18n.responsible_employee}
            </button>
          </div>
        </div>
        <div>
          <div
            className="remove-menu-block"
            onClick={() => {
              setMenuStaffsList([...menu_staffs_list.slice(0, menu_index), ...menu_staffs_list.slice(menu_index + 1)])
            }}>
            <button className="btn btn-orange"><i className="fa fa-minus"></i></button>
            <span>{props.i18n.delete}</span>
          </div>
        </div>
      </div>
    </div>
  )
})

const MenuStaffsList = sortableContainer(({props, menu_staffs_list, setMenuStaffsList, staff_states, setStaffStates, all_staff_ids, reservation_errors}) => {
  return (
    <div>
      {menu_staffs_list.map((menu_staffs_fields, menu_index) => {
        return (
          <MenuOptionField
            key={`menu-index-${menu_index}`}
            menu_staffs_list={menu_staffs_list}
            reservation_errors={reservation_errors}
            setMenuStaffsList={setMenuStaffsList}
            props={props}
            menu_staffs_fields={menu_staffs_fields}
            menu_index={menu_index}
            index={menu_index}
          />
        )
      })}

      <div
        className="add-menu-block"
        onClick={() => {
        const data = [...menu_staffs_list]
          setMenuStaffsList([...menu_staffs_list, {staff_ids: [{staff_id: null}]}])
        }}>
        <button className="btn btn-yellow">
          <i className="fa fa-plus" aria-hidden="true" ></i>
          {props.i18n.add_a_menu}
        </button>
      </div>
    </div>
  )
})

export default MenuStaffsList;
