"use strict";

import React, { useLayoutEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleOnlineService from "components/user_bot/sales/online_services"
import { SubmitButton } from "shared/components";

const ConfirmationStep = ({step, next, jump}) => {
  const { props, selected_online_service, selected_template, template_variables, introduction_video, product_content, selected_staff, price, normal_price, quantity, dispatch, createSalesOnlineServicePage } = useGlobalContext()

  useLayoutEffect(() => {
    $("body").scrollTop(0)
  }, [])

  return (
    <div className="form">
      <SalesFlowStepIndicator step={step} />
      <h4 className="header centerize"
        dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.sales.booking_page_creation.sale_page_confirm_title_html") }} />
      <div className="preview-hint">
        {I18n.t("user_bot.dashboards.sales.booking_page_creation.sale_page_like_this")}
      </div>
      <SaleOnlineService
        social_account_add_friend_url={props.social_account_add_friend_url}
        product={selected_online_service}
        template={selected_template.view_body}
        template_variables={template_variables}
        content={product_content}
        staff={selected_staff}
        jump={jump}
        dispatch={dispatch}
        demo={true}
        introduction_video={introduction_video}
        price={price}
        normal_price={normal_price}
        quantity={quantity}
        support_feature_flags={props.support_feature_flags}
        company_info={selected_online_service.company_info}
      />

      <div className="action-block confirm-block">
        <SubmitButton
          handleSubmit={createSalesOnlineServicePage}
          submitCallback={next}
          btnWord={I18n.t("user_bot.dashboards.sales.booking_page_creation.create_this_sale_page")}
        />
      </div>
    </div>
  )

}

export default ConfirmationStep
