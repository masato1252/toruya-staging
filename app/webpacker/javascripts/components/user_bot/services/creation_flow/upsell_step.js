"use strict";

import React, { useEffect } from "react";
import ReactSelect from "react-select";
import _ from "lodash";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import BookingSaleTemplateView from "components/user_bot/sales/booking_pages/sale_template_view";
import ServiceSaleTemplateView from "components/user_bot/sales/online_services/sale_template_view";

const UpsellStep = ({next, prev, step}) => {
  const { props, dispatch, upsell, selected_goal } = useGlobalContext()
  const sale_page = upsell.sale_page;

  useEffect(() => {
    if (selected_goal === 'external') {
      dispatch({
        type: "SET_ATTRIBUTE",
        payload: {
          attribute: "upsell",
          value: {
            type: "no",
          }
        }
      })

      next()
    }
  }, [])

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize break-line-content">{I18n.t("user_bot.dashboards.online_service_creation.what_want_to_upsell")}</h3>
      <div className="margin-around">
        <label className="text-align-left">
          <ReactSelect
            placeholder={I18n.t("user_bot.dashboards.online_service_creation.select_upsell_product")}
            value={ _.isEmpty(sale_page) ? "" : { label: sale_page.label }}
            options={props.upsell_sales}
            onChange={
              (page) => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "upsell",
                    value: {
                      type: "yes",
                      sale_page: page.value
                    }
                  }
                })
              }
            }
          />
        </label>

        {
          !_.isEmpty(sale_page) && (
            <>
              {sale_page.start_time}<br />
              {sale_page.end_time}

              <div className="sale-page margin-around">
                {
                  sale_page.product_type === 'BookingPage' ? (
                    <BookingSaleTemplateView
                      shop={sale_page.shop}
                      product={sale_page.product}
                      template={sale_page.template}
                      template_variables={sale_page.template_variables}
                      no_action={true}
                    />
                  ) : (
                    <ServiceSaleTemplateView
                      company_info={sale_page.product.company_info}
                      product={sale_page.product}
                      template={sale_page.template}
                      template_variables={sale_page.template_variables}
                      introduction_video={sale_page.introduction_video}
                      price={sale_page.price}
                      normal_price={sale_page.normal_price}
                      no_action={true}
                    />
                  )
                }
              </div>
            </>
          )
        }
      </div>

      <div className="action-block">
        <button onClick={next} className="btn btn-yellow"
          disabled={!upsell.type || (upsell.type === "yes" && _.isEmpty(upsell.sale_page))}>
          {I18n.t("action.next_step")}
        </button>
      </div>

      <div className="action-block">
        <button onClick={() => {
          dispatch({
            type: "SET_ATTRIBUTE",
            payload: {
              attribute: "upsell",
              value: {
                type: "no",
              }
            }
          })

          next()
        }} className="btn btn-tarco">
          {I18n.t("action.skip_step")}
        </button>
      </div>
    </div>
  )

}

export default UpsellStep
