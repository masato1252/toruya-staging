"use strict";

import React from "react";

const PriceBlock = ({product, demo}) => {
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
      ) :(
        <a href={product.url} className="btn btn-tarco" target="_blank">
          <i className="fas fa-calendar-check"></i> {I18n.t("action.book_now")}
        </a>
      )}
    </>
  )
}

export default PriceBlock
