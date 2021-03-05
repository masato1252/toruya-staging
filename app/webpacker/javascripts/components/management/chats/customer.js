"use strict";

import React, { useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

export default ({ customer }) => {
  const { selected_customer, dispatch }= useContext(GlobalContext)

  return (
    <div className={`customer ${customer.id === selected_customer.id ? "selected" : ""}`} >
      <div
        className="media"
        onClick={() => dispatch({
          type: "SELECT_CUSTOMER",
          payload: customer
        })
        }
      >
        <div className="media-left">
          <img className="media-object img-circle" src={customer.picture_url} />
        </div>
        <div className="media-body">
          { customer.name }
          { customer.shop_customer ? `(${customer.shop_customer.name})` : ""}
          { customer.unread_message_count ? `(${customer.unread_message_count})` : "" }
        </div>
      </div>
    </div>
  )
}
