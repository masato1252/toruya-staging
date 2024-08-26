"use strict"

import React from "react";

const CustomerCancelRequestField = ({i18n, register, watch}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="customer_cancel_request" type="radio" value="true" ref={register({ required: true })} />
        {i18n.customer_cancel_request_label}
      </label>
      {watch("customer_cancel_request") == "true" && (
        <label className="field-row flex-start">
          <input name="customer_cancel_request_before_day" type="number" ref={register({ required: true })} />
          {I18n.t("common.before_day_word")}
          {i18n.customer_cancel_request_before_day_label}
        </label>
      )}
      <label className="field-row flex-start">
        <input name="customer_cancel_request" type="radio" value="false" ref={register({ required: true })} />
        {i18n.not_customer_cancel_request_label}
      </label>
    </>
  )
}

export default CustomerCancelRequestField;
