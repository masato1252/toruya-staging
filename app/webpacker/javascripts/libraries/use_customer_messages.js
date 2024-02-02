import React, { useState, useEffect } from "react";
import { CustomerServices } from "user_bot/api";

const useCustomerMessages = (customer) => {
  const [messages, setMessages] = useState([])
  const [has_more_messages, setHasMoreMessages] = useState(null)

  useEffect(() => {
    fetchMessages()
  }, [customer.id])

  const fetchMessages = async () => {
    const oldest_message = messages.length ? messages[0] : null

    const [error, response] = await CustomerServices.messages({
      business_owner_id: customer.userId,
      id: customer.id,
      oldest_message_at: oldest_message ? oldest_message.created_at : null,
      oldest_message_id: oldest_message ? oldest_message.id : null
    });

    setMessages([...response.data.messages, ...messages])
    setHasMoreMessages(response.data.has_more_messages)
  }

  return { messages, has_more_messages, fetchMessages };
}

export default  useCustomerMessages
