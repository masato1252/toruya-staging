"use strict";

import React from "react";
import ReactSelect from "react-select";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";

const OnlineServiceSelectionStep = ({next, step}) => {
  const { props, selected_online_service, dispatch } = useGlobalContext()

  return (
    <div className="form settings-flow">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.online_service_creation.sell_what_service")}</h3>
      <div className="margin-around">
        <ReactSelect
          Value={selected_online_service ? { label: selected_online_service.internal_name } : ""}
          defaultValue={selected_online_service ? { label: selected_online_service.internal_name } : ""}
          placeholder={I18n.t("common.select_a_service")}
          options={props.online_services}
          onChange={
            (online_service_option)=> {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "selected_online_service",
                  value: online_service_option.value
                }
              })

              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "template_variables",
                  value: online_service_option.value.company_info.template_variables
                }
              })
            }
          }
        />
      </div>
      {selected_online_service && (
        <div className="item-container">
          <div className="item-element">
            <span>{I18n.t("common.content")}</span>
            <span className="item-data">{selected_online_service?.solution}</span>
          </div>
          <div className="item-element">
            <span>{I18n.t("user_bot.dashboards.sales.online_service_creation.service_start")}</span>
            <span className="item-data">{selected_online_service?.start_time_text}</span>
          </div>
          <div className="item-element">
            <span>{I18n.t("user_bot.dashboards.sales.online_service_creation.service_end")}</span>
            <span className="item-data">{selected_online_service?.end_time_text}</span>
          </div>
        </div>
      )}

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow" disabled={!selected_online_service}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default OnlineServiceSelectionStep
