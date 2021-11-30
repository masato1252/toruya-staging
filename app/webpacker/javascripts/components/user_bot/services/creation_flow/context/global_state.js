import React, { createContext, useReducer, useMemo, useContext } from "react";
import _ from "lodash";

import combineReducer from "context/combine_reducer";
import ServiceCreationReducer from "./service_creation_reducer";
import { OnlineServices } from "user_bot/api";

export const GlobalContext = createContext()

export const useGlobalContext = () => {
  return useContext(GlobalContext)
}

const reducers = combineReducer({
  services_creation_states: ServiceCreationReducer,
})

export const GlobalProvider = ({ props, children }) => {
  const initialValue = useMemo(() => {
    return _.merge(
      reducers(),
      {
        services_creation_states: {
        }
      }
    )
  }, [])
  const [state, dispatch] = useReducer(reducers, initialValue)

  const serviceData = () => {
    return {
      ...state.services_creation_states,
      upsell: {
        sale_page_id: state.services_creation_states.upsell?.sale_page?.id
      }
    }
  }

  const createService = async () => {
    const [error, response] = await OnlineServices.create_service(
      {
        data: serviceData()
      }
    )

    if (response?.data?.status == "successful") {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "online_service_slug",
          value: response.data.online_service_slug
        }
      })
    } else {
      alert(error?.message || response.data?.error_message)
    }

    return response?.data?.status == "successful"
  }

  const isReadyForPreview = () => {
    return selected_goal &&
      selected_solution &&
      !content_url &&
      end_type.end_type &&
      name &&
      selected_company
  }

  return (
    <GlobalContext.Provider value={{
      props,
      ...state.services_creation_states,
      dispatch,
      createService
    }}
    >
      {children}
    </GlobalContext.Provider>
  )
}
