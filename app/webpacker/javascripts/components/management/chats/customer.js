"use strict";

import React, { useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

export default ({ customer }) => {
  const { selected_customer, dispatch, subscription }= useContext(GlobalContext)

  return (
    <div className={`customer ${customer.id === selected_customer.id ? "selected" : ""}`} >
      <div className="media">
        <div className="media-left">
          <i
            className={`fa fa-thumbtack ${customer.pinned ? 'text-lime-400' : ''}`}
            onClick={() => {
              dispatch({
                type: "TOGGLE_CUSTOMER_PIN",
                payload: customer
              })

              subscription.perform("toggle_customer_pin", {
                customer_id: customer.id
              })
            }}>
          </i>
        </div>
        <div className="media-left">
          <img className="media-object img-circle" src={customer.picture_url} />
        </div>
        <div className="media-body"
          onClick={() => dispatch({
            type: "SELECT_CUSTOMER",
            payload: customer
          })
          }
        >
          { customer.name }
          { customer.shop_customer ? `(${customer.shop_customer.name})` : ""}
          { customer.unread_message_count ? `(${customer.unread_message_count})` : "" }
          <p>
            { customer.memo && customer.memo.slice(0, 10) }
          </p>
        </div>
      </div>
    </div>
  )
}
