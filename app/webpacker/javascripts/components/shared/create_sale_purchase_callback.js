"use strict";

import { SaleServices } from "user_bot/api";

const createSalePurchaseCallback = ({ purchase_data, payment_type, function_access_id }) => {
  return async (token, paymentIntentId, stripeSubscriptionId, setupIntentId) => {
    const [error, response] = await SaleServices.purchase({
      data: {
        ...purchase_data,
        token,
        payment_type,
        payment_intent_id: paymentIntentId,
        stripe_subscription_id: stripeSubscriptionId,
        setup_intent_id: setupIntentId,
        function_access_id
      }
    })

    if (error) {
      const errorMessage = error.response?.data?.error_message || 'Purchase failed'
      alert(errorMessage)
      throw new Error(errorMessage)
    }

    if (response.data.status === "successful") {
      window.location = response.data.redirect_to;
      return { status: "successful" };
    }
    else if (response.data.status === "requires_action") {
      return {
        requires_action: true,
        client_secret: response.data.client_secret,
        setup_intent_id: response.data.setup_intent_id,
        stripe_subscription_id: response.data.stripe_subscription_id,
        payment_intent_id: response.data.payment_intent_id
      }
    }
    else if (response.data.status === "failed") {
      const errorMessage = response.data.error_message || 'Purchase failed'
      alert(errorMessage)
      throw new Error(errorMessage)
    }
  }
}

export default createSalePurchaseCallback;
