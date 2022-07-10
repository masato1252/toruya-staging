"use strict";

import React from "react";
import ReactSelect from "react-select";
import _ from "lodash";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const BundledItemsStep = ({next, step, step_key}) => {
  const { props, dispatch, bundled_services } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} step_key={step_key} />
      <h3 className="header centerize break-line-content">{I18n.t("user_bot.dashboards.online_service_creation.what_want_to_sell_as_bundler")}</h3>
      <div className="margin-around">
        <label className="text-align-left">
          <ReactSelect
            placeholder={I18n.t("user_bot.dashboards.online_service_creation.select_bundler_product")}
            value={ _.isEmpty(bundled_services) ? "" : { label: bundled_services[bundled_services.length - 1].label }}
            options={props.bundled_service_candidates}
            onChange={
              (service) => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "bundled_services",
                    value: _.uniqBy([...bundled_services, { id: service.value.id, label: service.label, end_time: {} }], 'id')
                  }
                })
              }
            }
          />
        </label>
      </div>
      {bundled_services.length !== 0 && <div className="field-header">{I18n.t("user_bot.dashboards.online_service_creation.bundled_services")}</div>}
      <div className="margin-around">
        {bundled_services.length !== 0 && <p className="desc">{I18n.t("user_bot.dashboards.online_service_creation.bundled_service_usage_desc")}</p>}

        {bundled_services.map(bundled_service => (
          <button
            key={bundled_service.id}
            className="btn btn-gray mx-2 my-2"
            onClick={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "bundled_services",
                  value: bundled_services.filter(item => item.id !== bundled_service.id)
                }
              })
            }}>
            {bundled_service.label}
          </button>
        ))}
      </div>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow"
          disabled={bundled_services.length < 2}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default BundledItemsStep
