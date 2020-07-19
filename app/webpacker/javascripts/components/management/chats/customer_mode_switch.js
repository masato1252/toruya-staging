"use strict";

import React, { useContext } from "react";
import { GlobalContext } from "context/chats/global_state";

export default ({ customer }) => {
  const { toggleCustomerConversationState }= useContext(GlobalContext)

  return (
    <div className="switch-toggle switch-candy">
      <input
        type="radio"
        id={`customer-${customer.id}-one_on_one`}
        name={`customer_${customer.id}_conversation_state`}
        value="one_on_one"
        checked={customer.conversation_state === "one_on_one"}
        readOnly
      />
      <label
        htmlFor={`customer-${customer.id}-human`}
        onClick={(event) => {
          event.preventDefault()
          toggleCustomerConversationState(customer)
        }}
      >
        Human
      </label>

      <input
        type="radio"
        id={`customer-${customer.id}-bot`}
        value="bot"
        name={`customer_${customer.id}_conversation_state`}
        checked={customer.conversation_state === "bot"}
        readOnly
      />
      <label
        htmlFor={`customer-${customer.id}-bot`}
        onClick={(event) => {
          event.preventDefault()
          toggleCustomerConversationState(customer)
        }}
      >
        Bot
      </label>

      <a></a>
    </div>
 )
}
