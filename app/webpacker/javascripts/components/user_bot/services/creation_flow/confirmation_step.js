"use strict";

import React, { useState } from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import { SubmitButton } from "shared/components";
import OnlineServicePage from "user_bot/services/online_service_page";

const ConfirmationStep = ({next, prev, jump, step}) => {
  const { props, dispatch, createService, selected_company, name, selected_solution, content, upsell } = useGlobalContext()
  const company_info = props.companies.find((company) => company.id == selected_company.id && company.type == selected_company.type)

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.below_is_what_you_want")}</h3>
      <div className="preview-hint">
        {I18n.t("user_bot.dashboards.sales.booking_page_creation.sale_page_like_this")}
      </div>
      <OnlineServicePage
        company_info={company_info}
        name={name}
        solution={selected_solution}
        content={content}
        upsell_sale_page={upsell.sale_page}
        demo={true}
        jump={jump}
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
