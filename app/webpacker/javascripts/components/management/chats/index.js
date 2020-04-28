"use strict";
import React from "react";
import Consumer from "libraries/consumer";

class ChatChannels extends React.Component {
  componentDidMount = () => {
    Consumer.subscriptions.create(
      {
        channel: "UserChannel",
        user_id: this.props.super_user_id
      },
      {
        connected: () => {
          console.log("User Channel connected")
        },
        received: (data) => {
          console.log(data)
        },
        speak: () => {
        }
      }
    )
  }

  render() {
    return (
      <div />
    )
  }
}

export default ChatChannels;
