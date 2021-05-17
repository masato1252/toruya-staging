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
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)

  const broadcastData = () => {
    return _.pick(state.broadcast_creation_states, ["query", "content", "schedule_at"])
  }

  const createBroadcast = async () => {
    const [error, response] = await CommonServices.create(
      {
        url: Routes.lines_user_bot_broadcasts_path({format: "json"}),
        data: broadcastData()
      }
    )

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
      createBroadcast
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
