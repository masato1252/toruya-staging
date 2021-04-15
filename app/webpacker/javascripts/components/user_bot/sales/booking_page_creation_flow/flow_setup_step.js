"use strict";

import React from "react";
import TextareaAutosize from 'react-autosize-textarea';

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import FlowEdit from "components/user_bot/sales/flow_edit";

const FlowSetupStep = ({step, next, prev}) => {
  const { props, flow, dispatch } = useGlobalContext()

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <h4 className="header centerize"
        dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.sales.booking_page_creation.flow_introduction_html") }} />

      <div className="product-content-deails centerize">
        <h3 className="header centerize">
          {I18n.t("user_bot.dashboards.sales.booking_page_creation.flow_header")}
        </h3>
        <FlowEdit
          flow_tips={props.flow_tips}
          flow={flow}
          handleFlowChange={dispatch}
        />
      </div>

      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default FlowSetupStep
