"use strict"

import React from "react";
import I18n from 'i18n-js/index.js.erb';

const BookingPriceField = ({i18n, register}) => {
  return (
    <>
      <div className="field-row">
        <span>
          <input name="amount_cents" type="tel" ref={register({ required: true })} />
          {I18n.t("common.unit")}({I18n.t("common.tax_included")})
        </span>
        <input name="amount_currency" type="hidden" defaultValue="JPY" ref={register({ required: true })} />
      </div>
    </>
  )
}

export default BookingPriceField;
