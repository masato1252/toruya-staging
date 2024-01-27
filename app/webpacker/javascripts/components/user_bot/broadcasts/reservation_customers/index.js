import React, { useRef, useState, useEffect } from "react";

import { Translator, responseHandler } from "libraries/helper";
import { TopNavigationBar } from "shared/components"
import { CommonServices } from "user_bot/api";

const ReservationCustomerBroadcast = ({props}) => {
  const textareaRef = useRef();
  const [cursorPosition, setCursorPosition] = useState(0)
  const [content, setContent] = useState("")

  useEffect(() => {
    textareaRef.current.focus()
  }, [content.length])

  const insertKeyword = (keyword) => {
    const newContent = content.substring(0, cursorPosition) + keyword + content.substring(cursorPosition)

    setContent(newContent)
  }

  const onSubmit = async () => {
    const [error, response] = await CommonServices.create({
      url: Routes.lines_user_bot_shop_reservation_messages_path({
        business_owner_id: props.reservation.user_id, shop_id: props.reservation.shop_id, reservation_id: props.reservation.id
      }),
      data: {
        content
      }
    })

    responseHandler(error, response)
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view with-function-bar">
          <TopNavigationBar
            leading={
              <a href={props.previous_path}>
                <i className="fa fa-angle-left fa-2x"></i>
              </a>
            }
            title={I18n.t(`user_bot.dashboards.reservation.messages.broadcast_to_customer`)}
            />
          <h3 className="header centerize">{I18n.t("user_bot.dashboards.reservation.messages.broadcast_to_customer")}</h3>
          <div className="margin-around">
            {props.customer_names_sentence}
          </div>

          <h3 className="header centerize">{I18n.t("user_bot.dashboards.broadcast_creation.what_content_do_you_want")}</h3>
          <textarea
            ref={textareaRef}
            autoFocus={true}
            className="extend with-border"
            value={content}
            onChange={(event) => {
              setContent(event.target.value)
            }}
            onBlur={() => {
              setCursorPosition(textareaRef.current.selectionStart)
            }}
            onClick={() => {
              setCursorPosition(textareaRef.current.selectionStart)
            }}
          />
          <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.customer_name")} </button>
          <div className="preview-hint">{I18n.t("user_bot.dashboards.broadcast_creation.preview")}</div>
          <p className="margin-around p10 bg-gray rounded break-line-content">{Translator(content, {...props.message})}</p>

          <div className="margin-around centerize">
            <button onClick={onSubmit} className="btn btn-tarco" disabled={!content}>
              {I18n.t("action.send")}
            </button>
          </div>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default ReservationCustomerBroadcast;
