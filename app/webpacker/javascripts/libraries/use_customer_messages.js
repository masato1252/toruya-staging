import React, { useState, useEffect } from "react";
import { CustomerServices } from "user_bot/api";

const useCustomerMessages = (customer) => {
  const [messages, setMessages] = useState([])

  useEffect(() => {
    fetchMessages()
  }, [customer.id])

  const fetchMessages = async () => {
    const [error, response] = await CustomerServices.messages(customer.id);

    setMessages(response.data.messages)
  }

  return messages;
}

export default  useCustomerMessages
