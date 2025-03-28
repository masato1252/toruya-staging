"use strict";

import React, { useContext } from "react";
import ReactSelect from "react-select";
import { sortableContainer, sortableElement } from "react-sortable-hoc";

import { selectCustomStyles } from "libraries/styles";
import { displayErrors, arrayWithLength } from "libraries/helper";
import { DragHandle } from "shared/components";
import { GlobalContext } from "context/user_bots/reservation_form/global_state";

const MenuOptionField = sortableElement(({ menu_staffs_fields, menu_index }) => {
  const { menu_staffs_list, dispatch, props, reservation_errors } = useContext(GlobalContext)

  return (
    <div
      className="menu-option-field"
      data-controller="collapse"
      data-collapse-status="open"
    >
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
            data[menu_index]["menu_online"] = option.online
            data[menu_index]["staff_ids"] = arrayWithLength(Math.max(option.min_staffs_number, 1), { staff_id: "" })

            dispatch({
              type: "UPDATE_MENU_STAFFS_LIST",
              payload: [...data]
            })
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
              value={menu_staffs_fields.menu_required_time || ""}
              onChange={((event) => {
                const data = [...menu_staffs_list];
                data[menu_index]["menu_required_time"] = event.target.value

                dispatch({
                  type: "UPDATE_MENU_STAFFS_LIST",
                  payload: [...data]
                })
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

                  dispatch({
                    type: "UPDATE_MENU_STAFFS_LIST",
                    payload: [...data]
                  })
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
              {menu_staffs_fields.staff_ids.length > 1 && (
                <div
                  className="delete-staff-block"
                  onClick={() => {
                    const data = [...menu_staffs_list];
                    data[menu_index]["staff_ids"] = [
                      ...menu_staffs_list[menu_index]["staff_ids"].slice(0, staff_index),
                      ...menu_staffs_list[menu_index]["staff_ids"].slice(staff_index + 1)
                    ]

                    dispatch({
                      type: "UPDATE_MENU_STAFFS_LIST",
                      payload: [...data]
                    })
                  }}>

                  <button className="btn btn-orange">
                    <i className="fa fa-minus"></i>
                  </button>
                </div>
              )}
              {displayErrors(reservation_errors, [`reservation_form[menu_staffs_list][${menu_index}]staff_ids[${staff_index}][staff_id]`])}
            </div>
          )
        })}

          {props.reservation_properties.staff_options.length > 1 && (
            <div
              className="add-staff-block"
              onClick={() => {
                const data = [...menu_staffs_list];

                data[menu_index]["staff_ids"] = [...data[menu_index]["staff_ids"], {staff_id: null}]

                dispatch({
                  type: "UPDATE_MENU_STAFFS_LIST",
                  payload: [...data]
                })
              }}>
              <button className="btn btn-yellow">
                <i className="fa fa-user-plus" aria-hidden="true"></i> <span>{props.i18n.add_a_staff}</span>
              </button>
            </div>
          )}
          {menu_staffs_list.length > 1 && (
            <div
              className="remove-menu-block"
              onClick={() => {
                dispatch({
                  type: "UPDATE_MENU_STAFFS_LIST",
                  payload: [...menu_staffs_list.slice(0, menu_index), ...menu_staffs_list.slice(menu_index + 1)]
                })
              }}>
              <button className="btn btn-orange">
                <i className="fa fa-minus"></i> <span>{props.i18n.delete_a_menu}</span>
              </button>
            </div>
          )}
      </div>
    </div>
  )
})

const MenuStaffsList = sortableContainer(() => {
  const { menu_staffs_list, dispatch, props } = useContext(GlobalContext)

  return (
    <div>
      {menu_staffs_list.map((menu_staffs_fields, menu_index) => {
        return (
          <MenuOptionField
            key={`menu-index-${menu_index}`}
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

          dispatch({
            type: "UPDATE_MENU_STAFFS_LIST",
            payload: [...menu_staffs_list, {staff_ids: [{staff_id: null}]}]
          })
        }}>
        <button className="btn btn-yellow">
          <i className="fa fa-plus" aria-hidden="true" ></i> <span>{props.i18n.add_a_menu}</span>
        </button>
      </div>
    </div>
  )
})

export default MenuStaffsList;
