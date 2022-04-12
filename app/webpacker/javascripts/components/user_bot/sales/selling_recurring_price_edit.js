import React from "react";
import _ from "lodash";

import I18n from 'i18n-js/index.js.erb';

const SellingRecurringPriceEdit = ({price, handlePriceChange}) => (
  <>
    <div className="margin-around">
      <label className="">
        <div>
          <input
            name="selling_type" type="checkbox" value="month"
            checked={price.price_types.includes("month")}
            onChange={(event) => {
              if (event.target.checked) {
                price.price_types.push("month")

                handlePriceChange({
                  price_types: _.uniq(price.price_types),
                  price_amounts: price.price_amounts
                })
              }
              else {
                handlePriceChange({
                  price_types: price.price_types.filter((price_type) => price_type != 'month'),
                  price_amounts: price.price_amounts
                })
              }
            }}
          />
          <span>{I18n.t("common.month_pay")}</span>
          <br />
          {price.price_types.includes("month") && (
            <>
              <input
                type="tel"
                value={price.price_amounts?.month?.amount || ""}
                onChange={(event) => {
                  handlePriceChange({
                    price_types: price.price_types,
                    price_amounts: {
                      ...price.price_amounts,
                      month: {
                        amount: parseInt(event.target.value)
                      }
                    }
                  })
                }} />
                {I18n.t("common.unit")}
                ({I18n.t("common.tax_included")})
              </>
          )}
          </div>
        </label>
      </div>

      <div className="margin-around">
        <label className="">
          <div>
            <input
              name="selling_type" type="checkbox" value="year"
              checked={price.price_types.includes("year")}
              onChange={(event) => {
                if (event.target.checked) {
                  price.price_types.push("year")

                  handlePriceChange({
                    price_types: _.uniq(price.price_types),
                    price_amounts: price.price_amounts
                  })
                }
                else {
                  handlePriceChange({
                    price_types: price.price_types.filter((price_type) => price_type !== 'year'),
                    price_amounts: price.price_amounts
                  })
                }
              }}
            />
            <span>{I18n.t("common.year_pay")}</span>
            <br />
            {price.price_types.includes("year") && (
              <>
                <div>
                  <input
                    type="tel"
                    value={price.price_amounts?.year?.amount || ""}
                    onChange={(event) => {
                      handlePriceChange({
                        price_types: price.price_types,
                        price_amounts: {
                          ...price.price_amounts,
                          year: {
                            amount: parseInt(event.target.value)
                          }
                        }
                      })
                    }} />
                  {I18n.t("common.unit")}
                  ({I18n.t("common.tax_included")})
                </div>
              </>
            )}
          </div>
        </label>
      </div>
    </>
)

export default SellingRecurringPriceEdit
