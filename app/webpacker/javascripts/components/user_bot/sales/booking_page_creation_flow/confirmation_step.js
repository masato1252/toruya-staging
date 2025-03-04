"use strict";

import React, { useState, useLayoutEffect } from "react";

import { useGlobalContext } from "./context/global_state";
import SalesFlowStepIndicator from "./sales_flow_step_indicator";
import SaleBookingPage from "components/user_bot/sales/booking_pages"

const ConfirmationStep = ({step, next, jump}) => {
  const [submitting, setSubmitting] = useState(false)
  const { props, selected_booking_page, selected_template, template_variables, product_content, selected_staff, flow, dispatch, createSalesBookingPage } = useGlobalContext()

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
      <SaleBookingPage
        shop={props.shops[selected_booking_page.shop_id]}
        social_account_add_friend_url={props.social_account_add_friend_url}
        product={selected_booking_page}
        template={selected_template.view_body}
        template_variables={template_variables}
        content={product_content}
        staff={selected_staff}
        flow={flow}
        jump={jump}
        dispatch={dispatch}
        demo={true}
        support_feature_flags={props.support_feature_flags}
        company_info={props.shops[selected_booking_page.shop_id]}
      />
      <div className="action-block confirm-block">
        <button
          className="btn btn-yellow"
          disabled={submitting}
          onClick={async () => {
            if (submitting) return;
            setSubmitting(true)

            if (await createSalesBookingPage()) {
              setSubmitting(false)
              next()
            } else  {
              setSubmitting(false)
            }
          }}>
            {submitting ? (
              <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
            ) : (
              I18n.t("user_bot.dashboards.sales.booking_page_creation.create_this_sale_page")
            )}
          </button>
        </div>
    </div>
  )
}

export default ConfirmationStep
