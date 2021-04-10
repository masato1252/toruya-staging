import React, { useState } from "react";
import TextareaAutosize from 'react-autosize-textarea';

import I18n from 'i18n-js/index.js.erb';

const FlowEdit = ({flow_tips, flow, handleFlowChange}) => {
  return (
    <>
      {flow.map((flowStep, index) => {
        return (
          <div className="flow-step" key={`flow-step-${index}`}>
            <div className="number-step-header">
              <i>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</i>
              <div className="number-step">{index + 1}</div>
              <button className="btn btn-orange" onClick={() => handleFlowChange({ type: "REMOVE_FLOW", payload: { index } }) }>
                <i className="fa fa-minus"></i>
              </button>
            </div>

            <TextareaAutosize
              className="centerize extend with-border"
              placeholder={flow_tips[`tip${index + 1}`]}
              rows={1}
              value={flowStep}
              onChange={(event) => {
                handleFlowChange({
                  type: "SET_FLOW",
                  payload: {
                    index: index,
                    value: event.target.value
                  }
                })
              }}
            />
          </div>
        )
      })}
      <div className="action-block">
        <button className="btn btn-yellow" onClick={() => handleFlowChange({ type: "ADD_FLOW" }) }>
          {I18n.t("action.add_step")}
        </button>
      </div>
    </>
  )
}

export default FlowEdit
