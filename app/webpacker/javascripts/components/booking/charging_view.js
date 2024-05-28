"use strict";

import React from "react";

import StripeCheckoutForm from "shared/stripe_checkout_form"
import SquareCheckoutForm from "shared/square_checkout_form"

const ChargingView = ({booking_details, payment_solution, handleTokenCallback, product_name, product_price}) => {
  switch (payment_solution.solution) {
    case "stripe_connect":
      return (
        <div className="done-view">
          <StripeCheckoutForm
            stripe_key={payment_solution.stripe_key}
            handleToken={async (token) => {
              await handleTokenCallback(token)
            }}
            header={product_name}
            desc={booking_details}
            pay_btn={I18n.t("action.pay")}
            details_desc={product_price}
          />
        </div>
      )
    case "square":
      return (
        <div className="done-view">
          <SquareCheckoutForm
            square_app_id={payment_solution.square_app_id}
            square_location_id={payment_solution.square_location_id}
            handleToken={async (token, buyer) => {
              console.info({ token, buyer });
              await handleTokenCallback(token.token)
            }}
            header={product_name}
            desc={booking_details}
            pay_btn={I18n.t("action.pay")}
            details_desc={product_price}
          />
        </div>
      )
  }
}

export default ChargingView;
