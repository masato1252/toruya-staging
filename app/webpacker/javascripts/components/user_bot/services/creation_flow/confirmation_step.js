"use strict";

import React, { useLayoutEffect, useEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import { SubmitButton } from "shared/components";
import OnlineServicePage from "user_bot/services/online_service_page";

const ConfirmationStep = ({next, prev, jumpByKey, step, step_key}) => {
  const { props, dispatch, createService, selected_company, name, selected_solution, content_url, upsell } = useGlobalContext()
  const company_info = props.companies[0]

  useEffect(() => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "selected_company",
        value: {
          type: company_info.type,
          id: company_info.id
        }
      }
    })
  }, [])

  useLayoutEffect(() => {
    $("body").scrollTop(0)
  }, [])

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} step_key={step_key} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.below_is_what_you_want")}</h3>
      <div className="preview-hint">
        {I18n.t("user_bot.dashboards.online_service_creation.sale_page_like_this")}
      </div>
      <OnlineServicePage
        company_info={company_info}
        name={name}
        solution_type={selected_solution}
        content_url={content_url}
        upsell_sale_page={upsell.sale_page}
        demo={true}
        light={false}
        jumpByKey={jumpByKey}
      />

      <div className="action-block margin-around">
        <SubmitButton
          handleSubmit={createService}
          submitCallback={next}
          btnWord={I18n.t("user_bot.dashboards.online_service_creation.create_by_this_setting")}
        />
      </div>
    </div>
  )

}

export default ConfirmationStep
