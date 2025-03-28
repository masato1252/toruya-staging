"use strict";

import React from "react";
import Popup from 'reactjs-popup';
import Routes from 'js-routes.js';

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import LineVerificationWarning from 'shared/line_verification_warning';

const GoalSelectionStep = ({next, step}) => {
  const { props, dispatch, selected_goal } = useGlobalContext()

  if (selected_goal) return <></>

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} step_key="goal_step" />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_is_your_goal")}</h3>
      {props.service_goals.map((goal) => {
        if (goal.stripe_required && !props.user_payable) {
          return (
            <Popup
              trigger={
                <button
                  className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative servica-goal-btn-size"
                  disabled={!goal.enabled}
                  key={goal.key}>
                  <h4>{goal.name}</h4>
                  <p className="break-line-content text-align-left mt-2">
                    {goal.description}
                  </p>
                  {!goal.enabled && <span className="preparing">{I18n.t('common.preparing')}</span>}
                </button>
              }
              modal
              nested
            >
              <>
                <div className="modal-body">
                  {I18n.t("user_bot.dashboards.online_service_creation.stripe_required_warning")}
                </div>
                <div className="modal-footer centerize">
                  <a
                    href={Routes.lines_user_bot_settings_stripe_path(props.business_owner_id)}
                    className="btn btn-yellow">
                    {I18n.t("action.stripe_setting_btn")}
                  </a>
                </div>
              </>
            </Popup>
          )
        }
        else if (goal.premium_member_required && !props.is_premium_member)
          return (
            <a href="#"
              data-controller="modal"
              data-modal-target="#dummyModal"
              data-action="click->modal#popup"
              data-modal-path={Routes.create_course_lines_user_bot_warnings_path({ business_owner_id: props.business_owner_id })}
              className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative servica-goal-btn-size"
              disabled={!goal.enabled}
              key={goal.key}>
              <h4>{goal.name}</h4>
              <p className="break-line-content text-align-left mt-2">
                {goal.description}
              </p>
              {!goal.enabled && <span className="preparing">{I18n.t('common.preparing')}</span>}
            </a>
          )
        else {
          return (
            <button
              onClick={() => {
                if (!goal.enabled) return;
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "selected_goal",
                    value: goal.key
                  }
                })
              }}
              className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative servica-goal-btn-size"
              disabled={!goal.enabled}
              key={goal.key}>
              <h4>{goal.name}</h4>
              <p className="break-line-content text-align-left mt-2">
                {goal.description}
              </p>
              {!goal.enabled && <span className="preparing">{I18n.t('common.preparing')}</span>}
            </button>
          )
        }
      })}
    </div>
  )
}

export default GoalSelectionStep
