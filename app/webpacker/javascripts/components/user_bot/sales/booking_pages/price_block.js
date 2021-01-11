"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import { BookingStartInfo, BookingEndInfo, AddLineFriendInfo } from "shared/booking";

const PriceBlock = ({product, demo, social_account_add_friend_url}) => {
  const renderActions = () => {
    if (!product.is_started) {
      return (
        <>
          <BookingStartInfo start_at={product.start_at} />
          <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
        </>
      )
    }
    else if (product.is_ended) {
      return (
        <>
          <BookingEndInfo />
          <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
        </>
      )
    }
    else {
      return (
        <a href={product.url} className="btn btn-tarco" target="_blank">
          <i className="fas fa-calendar-check"></i> {I18n.t("action.book_now")}
        </a>
      )
    }
  }

  return (
    <>
      <div className="product-price-block">
        <div className="price-label">{I18n.t("common.booking_price")}</div>
        <div className="price">
          {product.price_number}<span className="price-with-tax">{I18n.t("common.unit")}+{I18n.t("common.tax")}</span>
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
