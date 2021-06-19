"use strict";

import React, { useState, useRef } from "react";
import ReactSelect from "react-select";
import _ from "lodash";

import { BookingOptionElement } from "shared/components";
import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";

const MenuSelectionStep = ({next, jump, step}) => {
  const { selected_menu, props, i18n, dispatch, menus, booking_options, new_menu_name, new_menu_minutes, new_menu_online_state } = useGlobalContext()
  const [creatingNewMenu, setCreatingNewMenu] = useState(false)
  const menuNameInpuRef = useRef()
  const menuMinutesRef = useRef()

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

          {<button className="btn btn-yellow" onClick={next}>{i18n.create_new_booking_option}</button>}
        </div>
      )
    }
  }

  const renderAllOptions = () => {
    if (creatingNewMenu) {
      if (!new_menu_name) {
        return (
          <div className="centerize">
            <h3 className="header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_name")}</h3>
            <div>
              <input className="extend with-border" ref={menuNameInpuRef} type="text" placeholder={I18n.t("user_bot.dashboards.booking_page_creation.input_menu_name")}/>
            </div>

            <button
              className="btn btn-yellow"
              onClick ={
                () => {
                  dispatch({
                    type: "SET_NEW_MENU",
                    payload: {
                      value: menuNameInpuRef.current.value
                    }
                  })
                }
              }>
              {I18n.t("action.next_step")}
            </button>
          </div>
        )
      }
      else if (!new_menu_minutes) {
        return (
          <div className="centerize">
            <h3 className="header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_time")}</h3>

            {[30, 60, 90].map(minute => (
              <button key={minute} className="btn btn-tarco btn-extend btn-tall"
                onClick={
                  () => {
                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "new_menu_minutes",
                        value: minute
                      }
                    })
                  }
                }
              >
                {minute} {I18n.t("common.minute")}
              </button>
              ))}
              <div className="action-block">
                <input type="tel" ref={menuMinutesRef} /> {I18n.t("common.minute")}

                <button className="btn btn-yellow"
                  onClick={
                    () => {
                      dispatch({
                        type: "SET_ATTRIBUTE",
                        payload: {
                          attribute: "new_menu_minutes",
                          value: menuMinutesRef.current.value || 60
                        }
                      })
                    }
                  }>
                  {I18n.t("action.next_step")}
                </button>
              </div>
            </div>
        )
      }
      else if (!new_menu_online_state) {
        return (
          <div className="centerize">
            <h3 className="header">{I18n.t("user_bot.dashboards.booking_page_creation.is_menu_online")}</h3>

            {["online", "local"].map(online_state => (
              <button key={online_state} className="btn btn-tarco btn-extend btn-tall"
                onClick={
                  () => {
                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "new_menu_online_state",
                        value: online_state
                      }
                    })

                    next()
                  }
                }
              >
                {I18n.t(`user_bot.dashboards.booking_page_creation.menu_${online_state}`)}
              </button>
            ))}
          </div>
        )
      }
    }
    else {
      return (
        <>
          <h3 className="header centerize">{i18n.choose_which_option}</h3>
          <ReactSelect
            placeholder={i18n.select_a_menu}
            value={ _.isEmpty(selected_menu) ? "" : selected_menu}
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
          <h3 className="header centerize">{I18n.t("user_bot.dashboards.booking_page_creation.want_to_create_a_new_menu")}</h3>
          <div className="centerize">
            <button className="btn btn-orange" onClick={() => { setCreatingNewMenu(true) }}>
              {I18n.t("user_bot.dashboards.booking_page_creation.create_a_new_menu")}
            </button>
          </div>

          <div className="field-header">{i18n.current_booking_options_label}</div>
          <div>
            {renderFilterBookingOptions()}
          </div>
        </>
      )
    }

  }

  return (
    <div className="form booking-creation-flow">
      <BookingFlowStepIndicator step={step} i18n={i18n} />
      {renderAllOptions()}

    </div>
  )
}

export default MenuSelectionStep
