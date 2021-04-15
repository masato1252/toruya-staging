"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const FlowView = ({flow, jump, demo}) => {
  if (!flow) return <></>

  return (
    <div className="flow-content content">
      {demo && (
        <span className="btn btn-yellow edit-mark" onClick={() => jump(6)}>
          <i className="fa fa-pencil-alt"></i>
          {I18n.t("action.edit")}
        </span>
      )}
      <h3 className="header centerize">
        {I18n.t("user_bot.dashboards.sales.booking_page_creation.flow_header")}
      </h3>
      {flow.map((flowStep, index) => {
        return (
          <div className="flow-step" key={`flow-step-${index}`}>
            <div className="number-step-header">
              <div className="number-step">{index + 1}</div>
            </div>
            <p>
              {flowStep}
            </p>
          </div>
        )
      })}
    </div>
  )
}

export default FlowView
