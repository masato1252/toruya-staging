"use strict"

import React from "react";

const CustomerCancelRequestField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="customer_cancel_request" type="radio" value="true" ref={register({ required: true })} />
        {i18n.customer_cancel_request_label}
      </label>
      <label className="field-row flex-start">
        <input name="customer_cancel_request" type="radio" value="false" ref={register({ required: true })} />
        {i18n.not_customer_cancel_request_label}
      </label>
    </>
  )
}

export default CustomerCancelRequestField;
