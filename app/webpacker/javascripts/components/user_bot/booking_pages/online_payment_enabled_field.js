"use strict"

import React from "react";

const OnlinePaymentEnabledField = ({i18n, register}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="online_payment_enabled" type="radio" value="true" ref={register({ required: true })} />
        {i18n.online_payment_options.enabled}
      </label>
      <label className="field-row flex-start">
        <input name="online_payment_enabled" type="radio" value="false" ref={register({ required: true })} />
        {i18n.online_payment_options.disabled}
      </label>
      <div className="margin-around centerize">
        <div dangerouslySetInnerHTML={{ __html: i18n.online_payment_enabled_desc_html }} />
      </div>
    </>
  )
}

export default OnlinePaymentEnabledField;
