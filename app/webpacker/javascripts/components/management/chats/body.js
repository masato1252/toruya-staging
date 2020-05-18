"use strict";

import React, { useContext } from "react";

import { GlobalContext } from "context/chats/global_state"
import MessageList from "./message_list"

export default () => {
  const { selected_channel_id, customers } = useContext(GlobalContext)
  const channel_customers = customers[selected_channel_id] || []

  if (selected_channel_id && channel_customers.length !== 0) {
    return <MessageList />
  }
  else if (selected_channel_id) {
    return (
      <div className="content-centerize">
        <p className="warning">
          You don't have any line customers yet, please invite them to add your official account.<br />
          If they already join, please ask them to send you any message.
        </p>
      </div>
    )
  }
  else {
    return (
      <div className="content-centerize">
        <p className="warning">
          You haven't set up your line account yet, <br />please set up in your setting page.
        </p>
      </div>
    )
  }
}
