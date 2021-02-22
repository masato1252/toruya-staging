"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import { AddLineFriendInfo } from "shared/booking";

const PriceBlock = ({demo, selling_price, normal_price, is_started, is_ended, purchase_url, social_account_add_friend_url, no_action}) => {
  const renderActions = () => {
    if (no_action) return <></>

    // end_time < now
    if (!is_started) {
      return (
        <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
      )
    }
    else if (is_ended) {
      return (
        <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
      )
    }
    else {
      return (
        <a href={purchase_url || "#"} className="btn btn-tarco" target="_blank">
          <i className="fas fa-calendar-check"></i> {I18n.t("action.book_now")}
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
                <div className="label">通常</div>
                <div className="amount">{normal_price}<span className="price-with-tax">{I18n.t("common.unit")}+{I18n.t("common.tax")}</span></div>
              </span>

              <i className="fa fa-arrow-right"></i>
            </>
          )}
          <span className="special-price">
            <div className="label">今なら</div>
            <div>{selling_price || '無料'} {selling_price && <span className="price-with-tax">{I18n.t("common.unit")}+{I18n.t("common.tax")}</span>}</div>
          </span>
        </div>
      </div>

      {demo ? (
        <button className="btn btn-tarco btn-large btn-tall btn-icon watch">
          <i className="fas fa-credit-card"></i> 今すぐ視聴する
        </button>
      ) :
        renderActions()
      }
      </>
  )
}

export default PriceBlock
