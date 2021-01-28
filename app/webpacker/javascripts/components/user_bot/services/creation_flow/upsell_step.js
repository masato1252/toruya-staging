"use strict";

import React from "react";
import ReactSelect from "react-select";

import { useGlobalContext } from "./context/global_state";
import ServiceFlowStepIndicator from "./services_flow_step_indicator";
import SaleTemplateView from "components/user_bot/sales/booking_pages/sale_template_view";

const UpsellStep = ({next, prev, step}) => {
  const { props, dispatch, upsell } = useGlobalContext()

  return (
    <div className="form settings-flow centerize">
      <ServiceFlowStepIndicator step={step} />
      <h3 className="header centerize break-line-content">{I18n.t("user_bot.dashboards.online_service_creation.what_want_to_upsell")}</h3>
      <div className="margin-around">
        <label className="">
          <input name="upsell" type="radio" value="no"
            checked={upsell.type === "no"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "upsell",
                  value: {
                    type: "no",
                  }
                }
              })
            }}
          />
          {I18n.t("user_bot.dashboards.online_service_creation.no_upsell")}
        </label>
      </div>

      <div>
        <label className="text-align-left">
          <input name="upsell" type="radio" value="yes"
            checked={upsell.type === "yes"}
            onChange={() => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "upsell",
                  value: {
                    type: "yes",
                  }
                }
              })
            }}
          />
          {I18n.t("user_bot.dashboards.online_service_creation.want_upsell")}
          {upsell.type === "yes" && (
            <ReactSelect
              placeholder={I18n.t("user_bot.dashboards.online_service_creation.select_upsell_product")}
              value={ _.isEmpty(upsell.sale_page) ? "" : { label: upsell.sale_page.label }}
              options={props.upsell_sales}
              onChange={
                (sale_page) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "upsell",
                      value: {
                        type: "yes",
                        sale_page: sale_page.value
                      }
                    }
                  })
                }
              }
            />
          )}
        </label>

        {
          !_.isEmpty(upsell.sale_page) && (
            <>
              {upsell.sale_page.start_time}
              {upsell.sale_page.end_time}

              <div className="sale-page margin-around">
                <SaleTemplateView
                  shop={upsell.sale_page.shop}
                  product={upsell.sale_page.product}
                  template={upsell.sale_page.template}
                  template_variables={upsell.sale_page.template_variables}
                  no_action={true}
                />
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
    </div>
  )

}

export default UpsellStep
