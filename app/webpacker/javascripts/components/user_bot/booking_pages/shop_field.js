"use strict"

import React from "react";

const ShopField = ({shop_options, i18n, register}) => {
  return (
    <>
      {shop_options.map(shop_option => (
        <label className="field-row flex-start" key={`shop-id-${shop_option.value}`}>
          <input name="shop_id" type="radio" value={shop_option.value} ref={register({ required: true })} />
          {shop_option.label}
        </label>
      ))}
    </>
  )
}

export default ShopField;
