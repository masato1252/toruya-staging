"use strict";

import React from 'react';

import ChargingView from "components/booking/charging_view";
import createSalePurchaseCallback from "shared/create_sale_purchase_callback";

const ServiceCheckoutForm = ({
  stripe_key,
  purchase_data,
  company_name,
  service_name,
  price,
  payment_type,
  function_access_id,
  business_owner_id,
  is_subscription = false
}) => {
  return (
    <ChargingView
      booking_details={service_name}
      payment_solution={{
        solution: "stripe_connect",
        stripe_key: stripe_key
      }}
      handleTokenCallback={createSalePurchaseCallback({
        purchase_data,
        payment_type,
        function_access_id
      })}
      product_name={company_name}
      product_price={price}
      business_owner_id={business_owner_id}
      is_subscription={is_subscription}
    />
  )
}

export default ServiceCheckoutForm;
