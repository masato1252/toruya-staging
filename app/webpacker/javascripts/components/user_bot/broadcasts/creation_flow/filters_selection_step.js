"use strict";

import React, { useEffect } from "react";

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";
import LineVerificationWarning from 'shared/line_verification_warning';

const FiltersSelectionStep = ({next, step}) => {
  const { props, dispatch } = useGlobalContext()

  useEffect(() => {
    if (props.broadcast.query_type) next()
  }, [])

  useEffect(() => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "query",
        value:  {
          filters: []
        }
      }
    })
  }, [])

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <LineVerificationWarning line_settings_verified={props.line_settings_verified} line_verification_url={props.line_verification_url} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.broadcast_creation.what_is_your_audiences")}</h3>
      {props.support_feature_flags.support_advance_broadcast && (
        <>
          <h4 className="header centerize">{I18n.t("user_bot.dashboards.broadcast_creation.target_reservation_customers")}</h4>
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
            disabled={!props.line_settings_verified}
            className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
            >
            <h4>{I18n.t("user_bot.dashboards.broadcast_creation.specific_menu_customers")}</h4>
            <p className="break-line-content">
              {I18n.t("user_bot.dashboards.broadcast_creation.specific_menu_customers_desc")}
            </p>
          </button>
          <h4 className="header centerize">{I18n.t("user_bot.dashboards.broadcast_creation.target_service_customers")}</h4>
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
            disabled={!props.line_settings_verified}
            className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
            >
            <h4>{I18n.t("user_bot.dashboards.broadcast_creation.specific_service_customers")}</h4>
            <p className="break-line-content">
              {I18n.t("user_bot.dashboards.broadcast_creation.specific_service_customers_desc")}
            </p>
          </button>
          <button
            onClick={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "query_type",
                  value: "online_service_for_active_customers"
                }
              })

              next()
            }}
            disabled={!props.line_settings_verified}
            className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
            >
            <h4>{I18n.t("user_bot.dashboards.broadcast_creation.specific_available_service_customers")}</h4>
            <p className="break-line-content">
              {I18n.t("user_bot.dashboards.broadcast_creation.specific_available_service_customers_desc")}
            </p>
          </button>
        </>
      )}


      <h4 className="header centerize">{I18n.t("user_bot.dashboards.broadcast_creation.target_customers_by_data")}</h4>
      <button
        onClick={() => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "query_type",
              value: "active_customers"
            }
          })

          next()
        }}
        disabled={!props.line_settings_verified}
        className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
        >
        <h4>{I18n.t("user_bot.dashboards.broadcast_creation.active_customers")}</h4>
        <p className="break-line-content">
          {I18n.t("user_bot.dashboards.broadcast_creation.active_customers_desc")}
        </p>
      </button>
      {props.support_feature_flags.support_advance_broadcast && (
      <>
        <button
          onClick={() => {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "query",
                value:  {
                  filters: [
                    {
                      field: "ranks.key",
                      condition: "eq",
                      value: "vip"
                    },
                  ]
                }
              }
            })

            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "query_type",
                value: "vip_customers"
              }
            })

            next()
          }}
          disabled={!props.line_settings_verified}
          className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
          >
          <h4>{I18n.t("user_bot.dashboards.broadcast_creation.vip_customers")}</h4>
          <p className="break-line-content">
            {I18n.t("user_bot.dashboards.broadcast_creation.vip_customers_desc")}
          </p>
        </button>
      </>)}
      <button
        onClick={() => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "query_type",
              value: "customers_with_birthday"
            }
          })

          next()
        }}
        disabled={!props.line_settings_verified}
        className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
        >
        <h4>{I18n.t("user_bot.dashboards.broadcast_creation.customers_with_birthday")}</h4>
        <p className="break-line-content">
          {I18n.t("user_bot.dashboards.broadcast_creation.customers_with_birthday_desc")}
        </p>
      </button>
      <button
        onClick={() => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "query_type",
              value: "customers_with_tags"
            }
          })

          next()
        }}
        disabled={!props.line_settings_verified}
        className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
        >
        <h4>{I18n.t("user_bot.dashboards.broadcast_creation.customers_with_tags")}</h4>
        <p className="break-line-content">
          {I18n.t("user_bot.dashboards.broadcast_creation.customers_with_tags_desc")}
        </p>
      </button>
    </div>
  )
}

export default FiltersSelectionStep;