import React from "react";

import I18n from 'i18n-js/index.js.erb';

const SellingPriceEdit = ({price, handlePriceChange}) => (
  <>
    <div className="margin-around">
      <label className="">
        <div>
          <input
            name="selling_type" type="radio" value="one_time"
            checked={price.price_type === "one_time"}
            onChange={() => {
              handlePriceChange({
                price_type: "one_time"
              })
            }}
          />
          <span className="line-through">１回払い</span>
          <br />
          {price.price_type === "one_time" && (
            <>
              <input
                type="tel"
                value={price.price_amount || ""}
                onChange={(event) => {
                  handlePriceChange({
                    price_type: "one_time",
                    price_amount: event.target.value
                  })
                }} />
                {I18n.t("common.unit")}
              </>
          )}
          </div>
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <div>
            <input name="selling_type" type="radio" value="multiple_time" disabled={true} />
            <span className="line-through">分割払い</span>(準備中)
          </div>
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <div>
            <input
              name="selling_type"
              type="radio"
              value="free"
              checked={price.price_type === "free"}
              onChange={() => {
                handleNormalPriceChange({
                  price_type: "free"
                })
              }}
            />
            {I18n.t("user_bot.dashboards.sales.online_service_creation.sell_free_price")}
          </div>
        </label>
      </div>
    </>
)

export default SellingPriceEdit
