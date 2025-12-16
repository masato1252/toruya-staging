"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import { BookingStartInfo, BookingEndInfo, AddLineFriendInfo } from "shared/booking";

const PriceBlock = ({
  product,
  demo,
  social_account_add_friend_url,
  no_action,
  normal_price,
  support_feature_flags
}) => {
  const renderActions = () => {
    if (no_action) return <></>

    if (product.is_ended) {
      return (
        <>
          <BookingEndInfo />
          <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
        </>
      )
    }
    else if (!product.is_started) {
      return (
        <>
          <BookingStartInfo start_at={product.start_time} />
          <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
        </>
      )
    }
    else {
      return (
        <a href={product.url} className="btn btn-tarco btn-large btn-tall" target="_blank">
          <i className="fas fa-calendar-check"></i> {I18n.t("action.book_now")}
        </a>
      )
    }
  }

  const isFree = () => {
    return product.price_number === 0
  }

  return (
    <>
      <div className="product-price-block">
        <div className="price">
          {normal_price && (
            <>
              <span className="normal-price">
                <div className="label">{I18n.t("common.normal_price_label")}</div>
                <div className="amount">{normal_price}<span className="price-with-tax">{I18n.t("common.unit")} {support_feature_flags?.support_tax_include_display ? `(${I18n.t("common.tax_included")})` : ""}</span></div>
              </span>

              <i className="fa fa-arrow-right"></i>
            </>
          )}
          <span className="special-price">
            <div>
              <div className="label">{isFree() ? I18n.t("common.today_price_label") : I18n.t("common.booking_price")}</div>
              {isFree() ? I18n.t("common.free_price") : product.price_number}{!isFree() && <span className="price-with-tax">{I18n.t("common.unit")}{support_feature_flags?.support_tax_include_display ? `(${I18n.t("common.tax_included")})` : ""}</span>}
            </div>
          </span>
        </div>
      </div>

      {demo ? (
        <button className="btn btn-tarco btn-large btn-tall">
          <i className="fas fa-calendar-check"></i> {I18n.t("action.book_now")}
        </button>
      ) :
        renderActions()
      }
      </>
  )
}

export default PriceBlock