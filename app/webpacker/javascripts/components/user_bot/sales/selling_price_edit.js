import React from "react";
import _ from "lodash";

import I18n from 'i18n-js/index.js.erb';
import { SelectOptions } from "shared/components"

const SellingPriceEdit = ({price, handlePriceChange}) => (
  <>
    <div className="margin-around">
      <label className="">
        <div>
          <input
            name="selling_type" type="checkbox" value="one_time"
            checked={price.price_types.includes("one_time")}
            onChange={(event) => {
              if (event.target.checked) {
                price.price_types.push("one_time")

                handlePriceChange({
                  price_types: _.uniq(price.price_types),
                  price_amounts: price.price_amounts
                })
              }
              else {
                handlePriceChange({
                  price_types: price.price_types.filter((price_type) => price_type != 'one_time'),
                  price_amounts: price.price_amounts
                })
              }
            }}
          />
          <span>１回払い</span>
          <br />
          {price.price_types.includes("one_time") && (
            <>
              <input
                type="tel"
                value={price.price_amounts?.one_time?.amount || ""}
                onChange={(event) => {
                  handlePriceChange({
                    price_types: price.price_types,
                    price_amounts: {
                      ...price.price_amounts,
                      one_time: {
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
              name="selling_type" type="checkbox" value="multiple_times"
              checked={price.price_types.includes("multiple_times")}
              onChange={(event) => {
                if (event.target.checked) {
                  price.price_types.push("multiple_times")

                  handlePriceChange({
                    price_types: _.uniq(price.price_types),
                    price_amounts: price.price_amounts
                  })
                }
                else {
                  handlePriceChange({
                    price_types: price.price_types.filter((price_type) => price_type !== 'multiple_times'),
                    price_amounts: price.price_amounts
                  })
                }
              }}
            />
            <span>分割払い</span>
            <br />
            {price.price_types.includes("multiple_times") && (
              <>
                <input
                  type="tel"
                  value={price.price_amounts?.multiple_times?.amount || ""}
                  onChange={(event) => {
                    handlePriceChange({
                      price_types: price.price_types,
                      price_amounts: {
                        ...price.price_amounts,
                        multiple_times: {
                          ...(price.price_amounts?.multiple_times || {}),
                          amount: parseInt(event.target.value)
                        }
                      }
                    })
                  }} />
                  {I18n.t("common.unit")}
                  ({I18n.t("common.tax_included")})
                <select
                  name="multiple_times_times"
                  value={price.price_amounts?.multiple_times?.times || ""}
                  onChange={(event) => {
                    handlePriceChange({
                      price_types: price.price_types,
                      price_amounts: {
                        ...price.price_amounts,
                        multiple_times: {
                          ...(price.price_amounts?.multiple_times || {}),
                          times: parseInt(event.target.value)
                        }
                      }
                    })
                  }}
                >
                  <option value=""></option>
                  <SelectOptions options={[
                    { label: 2,  value: 2  },
                    { label: 3,  value: 3  },
                    { label: 4,  value: 4  },
                    { label: 5,  value: 5  },
                    { label: 6,  value: 6  },
                    { label: 7,  value: 7  },
                    { label: 8,  value: 8  },
                    { label: 9,  value: 9  },
                    { label: 10, value: 10 },
                    { label: 11, value: 11 },
                    { label: 12, value: 12 },
                  ]} />
                </select>
                {(price.price_amounts?.multiple_times?.amount || 0) * (price.price_amounts?.multiple_times?.times || 0) }
              </>
            )}
          </div>
        </label>
      </div>
    </>
)

export default SellingPriceEdit
