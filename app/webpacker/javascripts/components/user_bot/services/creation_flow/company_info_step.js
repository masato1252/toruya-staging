"use strict";

import React from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const CompanyInfoStep = ({next, step}) => {
  const { props, dispatch, selected_company } = useGlobalContext()

  if (selected_company) {
    const company_info = props.companies.find((company) => company.id == selected_company.id && company.type == selected_company.type)

    return (
      <div className="form settings-flow">
        <ServiceFlowStepIndicator step={step} />
        <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.this_is_company_info")}</h3>

        <div className="margin-around">
          <h3 className="header">{company_info.type === "Shop" ? I18n.t("common.shop_info") : I18n.t("common.company_info")}</h3>
          <p>{company_info.name}</p>
          <p>{company_info.address}</p>
          <p>{company_info.phone_number}</p>

          {company_info.logo_url && <img className="logo" src={company_info.logo_url} />}

          <div className="action-block">
            <button onClick={next} className="btn btn-yellow" disabled={false}>
              {I18n.t("action.next_step")}
            </button>
          </div>
          <p className="margin-around">
            {company_info.type === "Shop" ? I18n.t("user_bot.dashboards.online_service_creation.edit_shop_in_setting_page") : I18n.t("user_bot.dashboards.online_service_creation.edit_company_in_setting_page")}
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.what_company_info")}</h3>
      {props.companies.map(company => (
        <button
          key={company.label}
          onClick={() => {
            dispatch({
              type: "SET_ATTRIBUTE",
              payload: {
                attribute: "selected_company",
                value: {
                  type: company.type,
                  id: company.id
                }
              }
            })
          }}
          className="btn btn-tarco btn-extend btn-tall margin-around m10"
        >
          {company.label}
        </button>
      ))}
    </div>
  )

}

export default CompanyInfoStep
