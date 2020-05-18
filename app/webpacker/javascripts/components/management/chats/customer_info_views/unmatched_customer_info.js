
"use strict";

import React, { useState, useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

export default () => {
  const { selected_customer, dispatch, subscription, matched_shop_customers }= useContext(GlobalContext)
  const [keyword, setKeyword] = useState("")

  const onSubmit = (e) => {
    e.preventDefault();

    subscription.perform("search_shop_customers", {
      keyword
    })

    setKeyword("")
  }

  const connectCustomer = (shop_customer) => {
    dispatch({
      type: "CONNECT_CUSTOMER",
      payload: {
        shop_customer: shop_customer,
        social_customer: selected_customer
      }
    })

    subscription.perform("connect_customer", {
      shop_customer_id: shop_customer.id,
      social_customer_id: selected_customer.id
    })
  }

  return (
    <>
      <div className="info">
        Connect a shop customer with the line customer, you could reconnect with another customer at anytime.
      </div>
      <form className="form" onSubmit={onSubmit}>
        <div className="form-group">
          <input
            type="text"
            className="form-control"
            placeholder="Customer Name"
            value={keyword}
            onChange={(e) => setKeyword(e.target.value)}
          />
        </div>
        <div className="form-group">
          <button type="submit" className="btn btn-success" disabled={!keyword}>
            Search
          </button>
        </div>
      </form>
      {matched_shop_customers.length ? (
        <div className="matched-shop-customer-list">
          {matched_shop_customers.map((matched_shop_customer) => (
            <div
              key={`matched-shop-custome-${matched_shop_customer.id}`}
              className="matched-shop-customer-option"
              onClick={() => connectCustomer(matched_shop_customer) }
            >
              <p>{matched_shop_customer.name}</p>
              <p>{matched_shop_customer.address}</p>
            </div>
          ))}
        </div>
      ) : ""}
    </>
  )
}
