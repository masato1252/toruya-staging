"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import { ServiceStartInfo, ServiceEndInfo, AddLineFriendInfo } from "shared/booking";

const PriceBlock = ({demo, solution_type, selling_price, normal_price, is_started, start_at, is_ended, purchase_url, social_account_add_friend_url, no_action, payable}) => {
  const renderActions = () => {
    if (no_action) return <></>

    if (!payable) {
      return (
        <div className="booking-info">
          <div className="unpayable-view">
            <div className="title">
              <h3>{I18n.t("common.preparing")}</h3>

              <div className="message break-line-content">
                {I18n.t("online_service_page.under_construction")}
              </div>
            </div>
          </div>
        </div>
      )
    }

    if (is_ended) {
      return (
        <>
          <ServiceEndInfo />
          <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
        </>
      )
    }
    else if (!is_started) {
      return (
        <>
          <ServiceStartInfo start_at={start_at} />
          <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
        </>
      )
    }
    else {
      return (
        <a href={purchase_url || "#"} className="btn btn-tarco btn-large btn-tall btn-icon watch" target="_blank">
          <i className="fas fa-credit-card"></i> {I18n.t(`action.sales.${solution_type}`)}
        </a>
      )
    }
  }

  return (
    <>
      <div className="product-price-block">
        <div className="price">
          {normal_price && (
            <>
              <span className="normal-price">
                <div className="label">{I18n.t("common.normal_price_label")}</div>
                <div className="amount">{normal_price}<span className="price-with-tax">{I18n.t("common.unit")}+{I18n.t("common.tax")}</span></div>
              </span>

              <i className="fa fa-arrow-right"></i>
            </>
          )}
          <span className="special-price">
            <div className="label">{I18n.t("common.today_price_label")}</div>
            <div>{selling_price || I18n.t("common.free_price")} {selling_price && <span className="price-with-tax">{I18n.t("common.unit")}+{I18n.t("common.tax")}</span>}</div>
          </span>
        </div>
      </div>

      {demo ? (
        <button className="btn btn-tarco btn-large btn-tall btn-icon watch">
          <i className="fas fa-credit-card"></i> {I18n.t(`action.sales.${solution_type}`)}
        </button>
      ) :
        renderActions()
      }
      </>
  )
}

export default PriceBlock
