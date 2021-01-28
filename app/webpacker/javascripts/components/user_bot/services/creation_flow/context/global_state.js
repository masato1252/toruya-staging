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
  //
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
          attribute: "online_service_id",
          value: response.data.online_service_id
        }
      })
    } else {
      alert(error?.message || response.data?.error_message)
    }

    return response?.data?.status == "successful"
  }

  // const isStaffSetup = () => {
  //   return !(!selected_staff || !selected_staff?.picture_url || selected_staff?.picture_url?.length == 0 || selected_staff?.introduction == "")
  // }
  //
  // const isContentSetup = () => {
  //   return product_content.picture_url.length && product_content.desc1 !== "" && product_content.desc2 !== ""
  // }
  //
  // const isHeaderSetup = () => {
  //   return selected_template.edit_body.filter(block => block.component === "input").every(filterBlock => template_variables?.[filterBlock.name] != null)
  // }
  //
  const isReadyForPreview = () => {
    return selected_goal &&
      selected_solution &&
      !_.isEmpty(content) &&
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
