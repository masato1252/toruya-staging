"use strict";

import React from "react";
import ReactSelect from "react-select";

import { BookingOptionElement } from "shared/components";
import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";

const MenuSelectionStep = ({next, jump, step}) => {
  const { selected_menu, props, i18n, dispatch, menus, booking_options } = useGlobalContext()

  const renderFilterBookingOptions = () => {
    const filter_options = selected_menu.value ?
      booking_options.filter(booking_option => booking_option.menu_ids.includes(selected_menu.value)) : booking_options

    return (
      <>
        {filter_options.map((option) => (
          <BookingOptionElement
            key={option.value}
            i18n={i18n}
            booking_option={option}
            onClick={() => {
              dispatch({
                type: "SET_BOOKING_OPTION",
                payload: {
                  booking_option: option
                }
              })

              // note step
              jump(3)
            }}
          />
        ))}
      </>
    )
  }

  const renderMenuBlock = () => {
    if (selected_menu.value) {
      return (
        <div className="menu-info">
          <div className="menu-data">
            <span>{i18n.booking_option_required_time}</span>
            <span>{selected_menu.required_time}{i18n.minute}</span>
          </div>
          <div className="menu-data">
            <span>{i18n.min_staffs_number}</span>
            <span>{selected_menu.min_staffs_number}{i18n.minute}</span>
          </div>

          {<button className="btn btn-yellow" onClick={next}>{i18n.create_new_booking_option}</button>}
        </div>
      )
    }
  }

  return (
    <div className="form booking-creation-flow">
      <BookingFlowStepIndicator step={step} i18n={i18n} />
      <h3 className="header centerize">{i18n.choose_which_option}</h3>
      <ReactSelect
        placeholder={i18n.select_a_menu}
        value={selected_menu}
        options={menus}
        onChange={
          (menu) => {
            dispatch({
              type: "SET_MENU",
              payload: {
                menu: menu
              }
            })
          }
        }
      />

      {renderMenuBlock()}

      <div className="field-header">{i18n.current_booking_options_label}</div>
      <div>
        {renderFilterBookingOptions()}
      </div>
    </div>
  )
}

export default MenuSelectionStep
