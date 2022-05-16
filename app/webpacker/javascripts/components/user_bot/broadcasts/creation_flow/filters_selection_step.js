"use strict";

import React from "react";

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";

const FiltersSelectionStep = ({next, step}) => {
  const { props, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      {props.line_settings_verified ? "" : <div className="warning">{I18n.t("line_verification.unverified_warning_message")}</div>}
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.broadcast_creation.what_is_your_audiences")}</h3>
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
        <h4>{I18n.t("user_bot.dashboards.broadcast_creation.specific_menu_customers")}</h4>
        <p className="break-line-content">
          {I18n.t("user_bot.dashboards.broadcast_creation.specific_menu_customers_desc")}
        </p>
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
        <h4>{I18n.t("user_bot.dashboards.broadcast_creation.specific_service_customers")}</h4>
        <p className="break-line-content">
          {I18n.t("user_bot.dashboards.broadcast_creation.specific_service_customers_desc")}
        </p>
      </button>
    </div>
  )
}

export default FiltersSelectionStep;
