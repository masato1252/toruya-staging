import React from "react";

import I18n from 'i18n-js/index.js.erb';

const SellingNumberEdit = ({quantity, handleQuantityChange}) => (
  <>
    <div className="margin-around">
      <label className="">
        <div>
          <input name="quantity_type" type="radio" value="limited"
            checked={quantity.quantity_type === "limited"}
            onChange={() => {
              handleQuantityChange({
                quantity_type: "limited"
              })
            }}
          />
          {I18n.t("user_bot.dashboards.sales.online_service_creation.sell_limit_number")}
        </div>
        {quantity.quantity_type === "limited" && (
          <>
            <input
              name="quantity"
              type="tel"
              value={quantity.quantity_value || ""}
              onChange={(event) => {
                handleQuantityChange({
                  quantity_type: "limited",
                  quantity_value: event.target.value
                })
              }}
            />
            {I18n.t("user_bot.dashboards.sales.online_service_creation.until_people_number")}
          </>
        )}
      </label>
    </div>

    <div className="margin-around">
      <label className="">
        <input name="quantity_type" type="radio" value="never"
          checked={quantity.quantity_type === "unlimited"}
          onChange={() => {
            handleQuantityChange({
              quantity_type: "unlimited"
            })
          }}
        />
        {I18n.t("user_bot.dashboards.sales.online_service_creation.sell_unlimit_number")}
      </label>
    </div>
  </>
)

export default SellingNumberEdit;
