"use strict";

import React from "react";
import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const ExternalPurchaseUrlStep = ({next, step, step_key}) => {
  const { dispatch, external_purchase_url } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} step_key={step_key} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_external_purchase_url")}</h3>
      <input
        placeholder={I18n.t("user_bot.dashboards.online_service_creation.external_purchase_url_input_placeholder")}
        value={external_purchase_url || ""}
        onChange={(event) =>
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "external_purchase_url",
                value: event.target.value
              }
            })
        }
        type="text"
        className="extend with-border"
      />
      <p className="margin-around text-align-left">
        {I18n.t("user_bot.dashboards.online_service_creation.external_purchase_url_hint")}
      </p>

      {external_purchase_url && (
        <div className="action-block">
          <button onClick={next} className="btn btn-yellow" disabled={false}>
            {I18n.t("action.next_step")}
          </button>
        </div>
      )}
    </div>
  )
}

export default ExternalPurchaseUrlStep
