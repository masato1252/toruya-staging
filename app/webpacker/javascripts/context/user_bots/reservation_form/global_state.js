import React, { createContext, useReducer, useRef, useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";
import moment from "moment-timezone";

import combineReducer from "context/combine_reducer";
import reservationReducer from "context/user_bots/reservation_form/reservation_reducer";

export const GlobalContext = createContext()

const reducers = combineReducer({
  reservation_states: reservationReducer
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        reservation_states: {
          menu_staffs_list: props.reservation_form.menu_staffs_list,
          staff_states: props.reservation_form.staff_states,
          customers_list: props.reservation_form.customers_list,
          errors: {}
        }
      }
    )
  }, [])

  const [state, dispatch] = useReducer(reducers, initialValue)
  const [processing, setProcessing] = useState(false)
  const hook_form_methods = useForm({
    defaultValues: {
      start_time_date_part: props.reservation_form.start_time_date_part,
      start_time_time_part: props.reservation_form.start_time_time_part,
      end_time_date_part: props.reservation_form.end_time_date_part,
      end_time_time_part: props.reservation_form.end_time_time_part,
      memo: props.reservation_form.memo,
      meeting_url: props.reservation_form.meeting_url
    }
  });

  const { menu_staffs_list } = state.reservation_states

  const all_staff_ids = () => {
    return _.uniq(
      _.compact(
        _.flatMap(
          menu_staffs_list, (menu_mapping) => menu_mapping.staff_ids
        ).map((staff_element) => String(staff_element.staff_id))
      )
    )
  }

  const all_menu_ids = () => {
    return _.uniq(
      _.compact(
        _.flatMap(menu_staffs_list, (menu_mapping) => menu_mapping.menu_id)
      )
    )
  }

  const start_time_date_part = hook_form_methods.watch("start_time_date_part")
  const start_time_time_part = hook_form_methods.watch("start_time_time_part")

  const start_at = () => {
    if (!start_time_date_part || !start_time_time_part) {
      return;
    }

    return moment.tz(`${start_time_date_part} ${start_time_time_part}`, "YYYY-MM-DD HH:mm", props.timezone)
  }

  const end_at = () => {
    if (!start_at() || !_.filter(menu_staffs_list, (menu_fields) => !!menu_fields.menu?.value).length) {
      return;
    }

    const total_required_time = menu_staffs_list.reduce((sum, menu_fields) => sum + Number(menu_fields.menu_required_time || 0), 0)

    return start_at().add(total_required_time, "minutes")
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...hook_form_methods,
      ...state.reservation_states,
      dispatch,
      all_staff_ids,
      all_menu_ids,
      processing,
      setProcessing,
      start_time_date_part,
      start_time_time_part,
      start_at,
      end_at
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
