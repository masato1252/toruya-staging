"use strict";

import React, { useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SellingEndTimeEdit from "components/user_bot/sales/selling_end_time_edit";

const SellingTimeStep = ({step, next, prev, lastStep}) => {
  const { dispatch, end_time, isEndTimeSetup, isReadyForPreview, selected_online_service } = useGlobalContext()

  const default_end_time_type = () => {
    return selected_online_service.recurring_charge_required ? "never" : "end_at"
  }

  useEffect(() => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "end_time",
        value: { end_type: default_end_time_type() }
      }
    })
  }, [])

  return (
    <div className="form settings-flow centerize">
      <SalesFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.sales.online_service_creation.what_selling_end_at")}</h3>

      <SellingEndTimeEdit
        default_option={default_end_time_type()}
        end_time={end_time}
        handleEndTimeChange={(end_time_value) => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "end_time",
              value: end_time_value
            }
          })
        }}
      />

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={() => {(isReadyForPreview()) ? lastStep(2) : next()}} className="btn btn-yellow"
            disabled={!isEndTimeSetup()}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default SellingTimeStep
