"use strict";

import React from "react";
import Popup from 'reactjs-popup';
import Routes from 'js-routes.js';

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";

const FiltersSelectionStep = ({next, step}) => {
  const { props, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">{"Select what group customers you want to send"}</h3>
      <button
        onClick={() => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "query_type",
              value: "all"
            }
          })

          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "query",
              value: {}
            }
          })

          next()
        }}
        className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
        >
        <h4>{"All Customers"}</h4>
      </button>
      <button
        onClick={() => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "query_type",
              value: "menu"
            }
          })

          next()
        }}
        className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
        >
        <h4>{"Customers ever used a menu"}</h4>
      </button>
      <button
        onClick={() => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "query_type",
              value: "online_service"
            }
          })

          next()
        }}
        className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
        >
        <h4>{"Customers ever used a service"}</h4>
      </button>
    </div>
  )
}

export default FiltersSelectionStep;
