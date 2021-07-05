import React from "react";

import I18n from 'i18n-js/index.js.erb';

const NormalPriceEdit = ({normal_price, handleNormalPriceChange}) => (
  <>
    <div className="margin-around">
      <label className="">
        <div>
          <input
            name="selling_type" type="radio" value="cost"
            checked={normal_price?.price_type === "cost"}
            onChange={() => {
              handleNormalPriceChange({
                price_type: "cost"
              })
            }}
          />
          {I18n.t("user_bot.dashboards.sales.online_service_creation.normal_price_cost")}
          <br />
          {normal_price?.price_type === "cost" && (
            <>
              <input
                type="tel"
                value={normal_price.price_amount || ""}
                onChange={(event) => {
                  handleNormalPriceChange({
                    price_type: "cost",
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
          <input
            name="selling_type"
            type="radio"
            value="free"
            checked={normal_price?.price_type === "free"}
            onChange={() => {
              handleNormalPriceChange({
                price_type: "free"
              })
            }}
          />
          {I18n.t("user_bot.dashboards.sales.online_service_creation.normal_price_free")}
        </div>
      </label>
    </div>
  </>
)

export default NormalPriceEdit;
