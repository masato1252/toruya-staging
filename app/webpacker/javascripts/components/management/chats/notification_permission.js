import React, { useContext } from "react";
import { GlobalContext } from "context/chats/global_state"

export default () => {
  const { props } = useContext(GlobalContext)

  if (!props) return <></>

  return (
    <div className="notification-permission"
      data-controller="web-push-subscriber"
      data-web-push-subscriber-key={props.web_push.subscriber_key}
      data-web-push-subscriber-path={props.web_push.subscriber_path}>
      <div data-target="web-push-subscriber.askArea">
        <div>
          Turn on Customer Message Notification would improve your user experince, we highly recommend you to turn it on.
        </div>
        <div className="btn btn-success btn-small"
          data-action="click->web-push-subscriber#askPermission">
          OK
        </div>
      </div>
      <div data-target="web-push-subscriber.deniedArea">
        Turn on Customer Message Notification would improve your user experince, we highly recommend you to turn it on from your browser address.
      </div>
    </div>
  )
}
