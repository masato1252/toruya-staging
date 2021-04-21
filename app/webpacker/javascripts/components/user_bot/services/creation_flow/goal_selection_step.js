"use strict";

import React, { useState } from "react";
import Popup from 'reactjs-popup';
import Routes from 'js-routes.js';

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const GoalSelectionStep = ({next, step}) => {
  const { props, dispatch } = useGlobalContext()
  const [warningPopupOpen, setWarningPopupOpen] = useState(false)

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.stripe_required_warning")}</h3>
      {props.service_goals.map((goal) => {
        if (goal.stripe_required && !props.user_payable) {
          return (
            <Popup
              trigger={
                <button
                  className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
                  disabled={!goal.enabled}
                  key={goal.key}>
                  <h4>{goal.name}</h4>
                  <p className="break-line-content text-align-left">
                    {goal.description}
                  </p>
                  {!goal.enabled && <span className="preparing">{I18n.t('common.preparing')}</span>}
                </button>
              }
              modal
            >
              <>
                <div className="modal-body">
                  {I18n.t("user_bot.dashboards.online_service_creation.what_is_end_time")}
                </div>
                <div className="modal-footer centerize">
                  <a
                    href={Routes.lines_user_bot_settings_stripe_path()}
                    className="btn btn-yellow">
                    {I18n.t("action.stripe_setting_btn")}
                  </a>
                </div>
              </>
            </Popup>
          )
        }
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

                next()
              }}
              className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
              disabled={!goal.enabled}
              key={goal.key}>
              <h4>{goal.name}</h4>
              <p className="break-line-content text-align-left">
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
