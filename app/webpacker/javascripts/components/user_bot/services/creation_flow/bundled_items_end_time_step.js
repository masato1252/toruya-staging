"use strict";

import React from "react";
import _ from "lodash";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import { EndOnMonthRadio, EndOnDaysRadio, EndAtRadio, NeverEndRadio, SubscriptionRadio } from "shared/components";

const BundledItemsEndTimeStep = ({next, step, step_key}) => {
  const { props, dispatch, bundled_services } = useGlobalContext()

  const bundled_service_end_time_options = (bundled_service) => {
    return props.bundled_service_candidates.find(candidate_service => candidate_service.value.id == bundled_service.id).value.end_time_options;
  }

  const set_end_time_type = ({bundled_service, end_time_type}) => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "bundled_services",
        value: bundled_services.map(bundled_service_item => (
          bundled_service_item.id == bundled_service.id ? (
            {
              id: bundled_service_item.id, label: bundled_service_item.label, end_time: {
                end_type: end_time_type
              }
            }
          ) :
          {...bundled_service_item}
        )
        )
      }
    })
  }

  const set_end_time_value = ({bundled_service, end_time_type, end_time_value_key, end_time_value}) => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "bundled_services",
        value: bundled_services.map(bundled_service_item => (
          bundled_service_item.id == bundled_service.id ? (
            {
              id: bundled_service_item.id, label: bundled_service_item.label, end_time: {
                end_type: end_time_type,
                [end_time_value_key || end_time_type]: end_time_value
              }
            }
          ) :
          {...bundled_service_item}
        )
        )
      }
    })
  }

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} step_key={step_key} />
      <h3 className="header centerize break-line-content">{I18n.t("user_bot.dashboards.online_service_creation.what_want_to_upsell")}</h3>
      <div className="margin-around">
        {bundled_services.map(bundled_service => (
          <div key={bundled_service.id} >
            <div key={bundled_service.id} className="btn btn-gray mx-2 my-2">
              {bundled_service.label}
            </div>

            {bundled_service_end_time_options(bundled_service).includes('end_at') && (
              <EndAtRadio
                prefix={bundled_service.id}
                end_time={bundled_service.end_time}
                set_end_time_type={() => {
                  set_end_time_type({bundled_service, end_time_type: 'end_at'})
                }}
                set_end_time_value={(end_time_value) => {
                  set_end_time_value({bundled_service, end_time_type: 'end_at', end_time_value_key: 'end_time_date_part', end_time_value})
                }}
              />
            )}

            {bundled_service_end_time_options(bundled_service).includes('end_on_days') && (
              <EndOnDaysRadio
                prefix={bundled_service.id}
                end_time={bundled_service.end_time}
                set_end_time_type={() => {
                  set_end_time_type({bundled_service, end_time_type: 'end_on_days'})
                }}
                set_end_time_value={(end_time_value) => {
                  set_end_time_value({bundled_service, end_time_type: 'end_on_days', end_time_value})
                }}
              />
            )}

            {bundled_service_end_time_options(bundled_service).includes('end_on_months') && (
              <EndOnMonthRadio
                prefix={bundled_service.id}
                end_time={bundled_service.end_time}
                set_end_time_type={() => {
                  set_end_time_type({bundled_service, end_time_type: 'end_on_months'})
                }}
                set_end_time_value={(end_time_value) => {
                  set_end_time_value({bundled_service, end_time_type: 'end_on_months', end_time_value})
                }}
              />
            )}

            {bundled_service_end_time_options(bundled_service).includes('never') && (
              <NeverEndRadio
                prefix={bundled_service.id}
                end_time={bundled_service.end_time}
                set_end_time_type={() => {
                  set_end_time_type({bundled_service, end_time_type: 'never'})
                }}
              />
            )}

            {bundled_service_end_time_options(bundled_service).includes('subscription') && (
              <SubscriptionRadio
                prefix={bundled_service.id}
                end_time={bundled_service.end_time}
                set_end_time_type={() => {
                  set_end_time_type({bundled_service, end_time_type: 'subscription'})
                }}
              />
            )}
          </div>
        ))}
      </div>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow">
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )

}

export default BundledItemsEndTimeStep
