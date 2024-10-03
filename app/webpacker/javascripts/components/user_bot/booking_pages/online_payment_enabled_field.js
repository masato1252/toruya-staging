"use strict"

import React from "react";

const OnlinePaymentEnabledField = ({i18n, register, watch, payment_provider_options, booking_options_payment_options, booking_page_online_payment_options_ids, setBookingPageOnlinePaymentOptionsIds }) => {
  return (
    <>
      <label className="field-row flex-start">
        <input name="payment_option" type="radio" value="online" ref={register({ required: true })} />
        {i18n.payment_option_options.online}
      </label>
      {watch("payment_option") == "online" && payment_provider_options.length > 1 ? (
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
        <input name="payment_option" type="radio" value="offline" ref={register({ required: true })} />
        {i18n.payment_option_options.offline}
      </label>
      <label className="field-row flex-start">
        <input name="payment_option" type="radio" value="custom" ref={register({ required: true })} />
        {i18n.payment_option_options.custom}
      </label>
      {watch("payment_option") == "custom" ? (
        <>
          {booking_options_payment_options.map((booking_option_payment_option) => {
            return (
              <div className="field-row flex-col items-baseline" key={`booking_option_payment_option_${booking_option_payment_option.value}`}>
                <div>{booking_option_payment_option.label}</div>
                <div>
                  <label className="p-1">
                    <input
                      name={`booking_page_online_payment_options_ids_${booking_option_payment_option.value}`}
                      type="radio"
                      checked={booking_page_online_payment_options_ids?.includes(booking_option_payment_option.value)}
                      onChange={() => {
                        setBookingPageOnlinePaymentOptionsIds((prev) => ([...prev, booking_option_payment_option.value]))
                      }}
                    />
                    {i18n.payment_option_options.online}
                  </label>
                  <label className="p-1">
                    <input
                      name={`booking_page_online_payment_options_ids_${booking_option_payment_option.value}`}
                      type="radio"
                      checked={!booking_page_online_payment_options_ids?.includes(booking_option_payment_option.value)}
                      onChange={() => {
                        setBookingPageOnlinePaymentOptionsIds((prev) => (prev?.filter((id) => id != booking_option_payment_option.value)))
                      }}
                    />
                    {i18n.payment_option_options.offline}
                  </label>
                </div>
              </div>
            )
          })}
        </>
      ) : <></>}  


      <div className="margin-around centerize">
        <div className="warning">{I18n.t("errors.selling_price_too_low")}</div>
        <div dangerouslySetInnerHTML={{ __html: i18n.payment_option_desc_html }} />
      </div>
    </>
  )
}

export default OnlinePaymentEnabledField;
