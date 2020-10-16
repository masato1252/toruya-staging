import React, { createContext, useReducer, useRef, useMemo } from "react";
import _ from "lodash";

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

  return (
    <GlobalContext.Provider value={{
      props,
      ...state.reservation_states,
      dispatch,
      all_staff_ids,
      all_menu_ids
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
