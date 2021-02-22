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
      <h3 className="header centerize">どのサービスを販売しますか？</h3>
      <div className="margin-around">
        <ReactSelect
          Value={selected_online_service ? { label: selected_online_service.name } : ""}
          defaultValue={selected_online_service ? { label: selected_online_service.name } : ""}
          placeholder="サービスを選択"
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
            }
          }
        />
      </div>
      {selected_online_service && (
        <div className="item-container">
          <div className="item-element">
            <span>コンテンツ</span>
            <span className="item-data">{selected_online_service?.solution}</span>
          </div>
          <div className="item-element">
            <span>利用開始</span>
            <span className="item-data">{selected_online_service?.start_time_text}</span>
          </div>
          <div className="item-element">
            <span>利用終了</span>
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
