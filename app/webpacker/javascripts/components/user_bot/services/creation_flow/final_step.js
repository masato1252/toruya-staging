"use strict";

import React, { useState } from "react";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";

const FinalStep = ({step, step_key}) => {
  const { online_service_slug, props } = useGlobalContext()
  const [sale_page_later, build_sale_page_later] = useState(false)

  return (
    <div className="form settings-flow">
      <ServiceFlowStepIndicator step={step} step_key={step_key} />

      {
        sale_page_later ? (
          <div className="action-block">
            <h3 className="danger" dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.booking_page_creation.create_sale_page_later_warning_html") }} />
            <br />
            <h3>{I18n.t("user_bot.dashboards.booking_page_creation.remember_create_sale_page")}</h3>
          </div>
        ) : (
          <>
            <h3 className="header centerize">{I18n.t("user_bot.dashboards.online_service_creation.create_a_sale_page")}</h3>
            <div className="action-block">
              <a href={Routes.new_lines_user_bot_sales_online_service_url({business_owner_id: props.business_owner_id, slug: online_service_slug})} className="btn btn-yellow btn-flexible">
                <i className="fa fa-cart-arrow-down fa-4x"></i>
                <h4>{I18n.t("user_bot.dashboards.booking_page_creation.create_a_sale_page_btn")}</h4>
              </a>
              <br />
              <br />
              <a className="btn btn-tarco" onClick={() => { build_sale_page_later(true) }}>
                {I18n.t("user_bot.dashboards.booking_page_creation.create_sale_page_later_btn")}
              </a>
            </div>
          </>
        )
      }
      {props.support_feature_flags.support_japanese_asset ? (
        <div className="centerize margin-around">
          <img src={props.sale_page_introduction_path} className="w-full" />
        </div>
      ) : null}
    </div>
  )
}

export default FinalStep
