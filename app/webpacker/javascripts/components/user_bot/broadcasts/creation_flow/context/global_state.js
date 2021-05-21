import React, { createContext, useReducer, useMemo, useContext } from "react";
import Routes from 'js-routes.js'
import _ from "lodash";

import combineReducer from "context/combine_reducer";
import BroadcastCreationReducer from "./broadcast_creation_reducer";
import { CommonServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  broadcast_creation_states: BroadcastCreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        broadcast_creation_states: {
          ...props.broadcast
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)

  const broadcastData = () => {
    return _.pick(state.broadcast_creation_states, ["query", "content", "schedule_at"])
  }

  const fetchCustomersCount = async () => {
    if (state.broadcast_creation_states.query === null) return;

    const [error, response] = await CommonServices.update(
      {
        url: Routes.customers_count_lines_user_bot_broadcasts_path({format: "json"}),
        data: {
          query: state.broadcast_creation_states.query
        }
      }
    )

    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "customers_count",
        value: response.data.customers_count
      }
    })
  }

  const createBroadcast = async () => {
    let error, response

    if (state.broadcast_creation_states.id) {
      [error, response] = await CommonServices.update(
        {
          url: Routes.lines_user_bot_broadcast_path(state.broadcast_creation_states.id, {format: "json"}),
          data: broadcastData()
        }
      )
    }
    else {
      [error, response] = await CommonServices.create(
        {
          url: Routes.lines_user_bot_broadcasts_path({format: "json"}),
          data: broadcastData()
        }
      )
    }

    if (response?.data?.status == "successful") {
       window.location = response.data.redirect_to
    } else {
      alert(error?.message || response.data?.error_message)
    }
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...state.broadcast_creation_states,
      dispatch,
      createBroadcast,
      fetchCustomersCount
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
