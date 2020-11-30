"use strict"

import React from "react";

const BookingPriceField = ({i18n, register}) => {
  return (
    <>
      <div className="field-row">
        <input name="amount_cents" type="tel" ref={register({ required: true })} />
        <input name="amount_currency" type="hidden" defaultValue="JPY" ref={register({ required: true })} />
      </div>
      <div className="field-header">{i18n.tax_label}</div>
      <label className="field-row flex-start">
        <input name="tax_include" type="radio" value="true" ref={register({ required: true })} />
        {i18n.tax_include}
      </label>
      <label className="field-row flex-start">
        <input name="tax_include" type="radio" value="false" ref={register({ required: true })} />
        {i18n.tax_excluded}
      </label>
    </>
  )
}

export default BookingPriceField;
