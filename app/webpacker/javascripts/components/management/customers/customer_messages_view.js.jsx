"use strict";

import React, { useState, useEffect, useLayoutEffect, useRef } from "react";
import axios from 'axios';

import CustomerBasicInfo from "./basic_info.js";
import CustomerFeaturesTab from "./customer_features_tab.js";
import CustomersDashboard  from "./customers_dashboard.js";
import Message from "components/management/chats/message";

const CustomerMessagesView = (props) => {
  let processing = false;
  let customerMessagesCall = null;
  const [messages, setMessages] = useState([])
  const messageListRef = useRef(null);

  useEffect(() => {
    fetchMessages()
  }, [])

  useLayoutEffect(() => {
    messageListRef.current.scrollIntoView({ behavior: "auto" });
  }, [messages])

  const fetchMessages = () => {
    if (processing) return;

    processing = true;

    if (customerMessagesCall) {
      customerMessagesCall.cancel();
    }
    customerMessagesCall = axios.CancelToken.source();

    if (props.customer.id) {
      props.switchProcessing(function() {
        axios({
          method: "GET",
          url: props.customerMessagesPath,
          params: { id: props.customer.id },
          responseType: "json",
          cancelToken: customerMessagesCall.token
        }).then(function(response) {
          setMessages(response.data["messages"])
        }).catch(function() {
          setMessages([])
        }).then(function() {
          processing = false;
          props.forceStopProcessing();
        });
      });
    }
  };

  return (
    <div className="contBody">
      <div id="customerInfo">
        <CustomerBasicInfo
          customer={props.customer}
          groupBlankOption={props.groupBlankOption}
          switchCustomerReminderPermission={props.switchCustomerReminderPermission}
        />

        <CustomerFeaturesTab {...props} selected={CustomersDashboard.customerView.customer_messages} />

        <div id="chat-box" className="tabBody" style={{height: "425px"}}>
          {messages.map((message, index) => <Message message={message} key={`${props.customer.id}-${index}`} />)}
          <div ref={messageListRef} />
        </div>
      </div>
    </div>
  );
}

export default CustomerMessagesView;
