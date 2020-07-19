"use strict";

import React, { useEffect, useContext } from "react";

import { GlobalProvider } from "context/chats/global_state"
import App from "./app";

export const ChatChannels = (props) => {
  return (
    <GlobalProvider className="row">
      <App props={props} />
    </GlobalProvider>
  )
}

export default ChatChannels;
