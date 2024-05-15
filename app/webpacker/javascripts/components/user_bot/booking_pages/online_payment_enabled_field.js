"use strict"

import React from "react";

const OnlinePaymentEnabledField = ({i18n, register, watch, payment_provider_options}) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="online_payment_enabled" type="radio" value="true" ref={register({ required: true })} />
        {i18n.online_payment_options.enabled}
      </label>
      {watch("online_payment_enabled") == "true" && payment_provider_options.length > 1 ? (
        <div className="field-row flex-start">
          {payment_provider_options.map((provider_option) => {
            return (
              <label className="p-1" key={provider_option.value}>
                <input name="default_provider" type="radio" value={provider_option.value} ref={register({ required: true })} />
                {provider_option.label}
              </label>
            )
          })}
        </div>
      ) : <></>}
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
