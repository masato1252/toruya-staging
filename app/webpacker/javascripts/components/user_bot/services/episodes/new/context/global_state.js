import React, { createContext, useReducer, useMemo, useContext } from "react";
import _ from "lodash";
import Routes from 'js-routes.js'

import combineReducer from "context/combine_reducer";
import CreationReducer from "./creation_reducer";
import { CommonServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  creation_states: CreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        creation_states: {
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)

  const episodeData = () => {
    return {
      ...state.creation_states
    }
  }

  const createEpisode = async () => {
    const [error, response] = await CommonServices.create({
      url: Routes.lines_user_bot_service_episodes_path(props.online_service.id),
      data: episodeData()
    })

    if (response?.data?.status == "successful") {
      window.location = response.data.redirect_to
    } else {
      alert(error?.message || response.data?.error_message)
    }
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...state.creation_states,
      dispatch,
      createEpisode
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
