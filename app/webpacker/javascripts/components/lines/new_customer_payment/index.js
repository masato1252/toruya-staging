"use strict";

import React, { useState } from "react";
import I18n from 'i18n-js/index.js.erb';

import { CommonServices } from "user_bot/api";
import ChargingView from "components/booking/charging_view";

export const NewCustomerPayment = ({props}) => {
  const handleTokenCallback = async (paymentMethodId, paymentIntentId, stripeSubscriptionId) => {
    const [error, response] = await CommonServices.create({
      url: Routes.customer_payments_path(props.slug, {format: "json"}),
      data: {
        token: paymentMethodId,
        order_id: props.order_id,
        encrypted_social_service_user_id: props.encrypted_social_service_user_id,
        payment_intent_id: paymentIntentId,
        stripe_subscription_id: stripeSubscriptionId
      }
    })

    if (error) {
      throw new Error(error.response.data.error_message || 'Payment failed');
    }

    if (response.data.status === "successful") {
      window.location = response.data.redirect_to;
      return { status: "successful" };
    }
    else if (response.data.status === "requires_action") {
      return {
        requires_action: true,
        client_secret: response.data.client_secret,
        stripe_subscription_id: response.data.stripe_subscription_id,
        payment_intent_id: response.data.payment_intent_id
      }
    }
    else if (response.data.status === "failed") {
      throw new Error(response.data.error_message || 'Payment failed');
    }
  }

  return (
    <div className="done-view">
      <h3 className="title">
        {I18n.t("common.pay_the_payment")}
      </h3>
      <ChargingView
        booking_details={props.service_name}
        payment_solution={{
          solution: "stripe_connect",
          stripe_key: props.stripe_key
        }}
        handleTokenCallback={handleTokenCallback}
        product_name={props.company_name}
        product_price={props.price}
        business_owner_id={props.business_owner_id}
        is_subscription={props.is_subscription}
      />
    </div>
  )
}

export default NewCustomerPayment;
