"use strict";

import React, { useEffect } from "react";
import { useGlobalContext } from "context/user_bots/bookings/global_state";
import BookingFlowStepIndicator from "./booking_flow_step_indicator";

const ShopSelectionStep = ({next, step}) => {
  const { selected_shop, props, i18n, dispatch, fetchShopMenus } = useGlobalContext()

  useEffect(() => {
    if (selected_shop.id) {
      fetchShopMenus()
    }
  }, [selected_shop.id])

  return (
    <div className="booking-creation-flow centerize">
      <BookingFlowStepIndicator step={step} i18n={i18n} />

      {selected_shop.id ? (
        <>
          <h3 className="header">{i18n.book_for_this_shop}</h3>
          <div className="shop-info">
            <b>{i18n.short_name}</b>
            <p>{selected_shop.shortName}</p>

            <b>{i18n.company_info}</b>
            <p>
              {selected_shop.address}<br />
              {selected_shop.phoneNumber}
            </p>
            <b>{i18n.shop_logo}</b>
            <p>
              {selected_shop.logoUrl ?  <img className="logo" src={selected_shop.logoUrl} /> : i18n.shop_without_logo}
            </p>

            <div className="centerize">
              <button
                className="btn btn-yellow"
                onClick={next}>
                {I18n.t("action.next_step")}
              </button>
            </div>
          </div>
        </>
      ) : (
        <>
          <h3 className="header">{i18n.book_which_shop}</h3>
          {props.shops.map(shop => (
          <div key={`shop-${shop.id}-btn`}>
            <button
              onClick={() => {
                dispatch({
                  type: "SET_ATTRIBUTE",
                  payload: {
                    attribute: "selected_shop",
                    value: shop
                  }
                })
              }}
              className="btn btn-tarco btn-extend btn-tall">
              {shop.name}
            </button>
          </div>
          ))}
        </>
      )}
    </div>
  )

}

export default ShopSelectionStep
