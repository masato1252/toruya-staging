"use strict"

import React from "react";

const ShopField = ({shop_options, i18n, register}) => {
  return (
    <>
      {shop_options.map(shop_option => (
        <div className="field-row" key={`shop-id-${shop_option.value}`}>
          <label>
            <input name="shop_id" type="radio" value={shop_option.value} ref={register({ required: true })} />
            {shop_option.label}
          </label>
        </div>
      ))}
    </>
  )
}

export default ShopField;
