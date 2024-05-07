"use strict"

import React, { useEffect } from "react";
import I18n from 'i18n-js/index.js.erb';

import { ErrorMessage, TicketOptionsFields } from "shared/components";

const BookingPriceField = ({setValue, register, watch, ticket_expire_date_desc_path}) => {
  return (
    <>
      <div className="field-row">
        <span>
          <input name="amount_cents" type="tel" ref={register({ required: true })} />
          {I18n.t("common.unit")}({I18n.t("common.tax_included")})
          {watch("price_type") == "ticket" && watch("amount_cents") > 50000 &&
            <ErrorMessage error={I18n.t("settings.booking_option.form.form_errors.ticket_max_price_limit")} />}
        </span>
        <input name="amount_currency" type="hidden" defaultValue="JPY" ref={register({ required: true })} />
      </div>
      <TicketOptionsFields
        setValue={setValue}
        watch={watch}
        register={register}
        ticket_expire_date_desc_path={ticket_expire_date_desc_path}
        price={watch("amount_cents")}
      />
    </>
  )
}

export default BookingPriceField;
