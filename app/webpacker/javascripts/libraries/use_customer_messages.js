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

    const [error, response] = await CustomerServices.messages(
      customer.id,
      oldest_message ? oldest_message.created_at : null,
      oldest_message ? oldest_message.id : null
    );

    setMessages([...response.data.messages, ...messages])
    setHasMoreMessages(response.data.has_more_messages)
  }

  return { messages, has_more_messages, fetchMessages };
}

export default  useCustomerMessages
