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
      <div className="field-row">
        <span>
          You could set the booking number for your discounted price. We count for u<br />
          <br />
          <select name="ticket_quota" ref={register()}>
            {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
             12, 13, 14, 15, 16, 17, 18, 19, 20].map((num) => <option value={num}>{num}</option>)}
          </select>
          回の総価格
        </span>
      </div>
    </>
  )
}

export default BookingPriceField;
