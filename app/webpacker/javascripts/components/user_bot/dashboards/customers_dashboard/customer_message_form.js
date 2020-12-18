import React, { useState, useRef } from "react";
import moment from "moment-timezone";

import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { CustomerServices } from "components/user_bot/api"

const CustomerMessageForm = () => {
  moment.locale('ja');
  const ref = useRef()
  const { selected_customer, dispatch } = useGlobalContext()
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async () => {
    if (submitting) return;
    setSubmitting(true)

    const [error, response] = await CustomerServices.reply_message({ customer_id: selected_customer.id, message: ref.current.value })
    setSubmitting(false)

    if (response?.data?.status == "successful") {
      dispatch({
        type: "APPEND_NEW_MESSAGE",
        payload: {
          message: {
            message_type: "staff",
            text: ref.current.value,
            formatted_created_at: moment(Date.now()).format("llll")
          }
        }
      })

      ref.current.value = null;
    }
  }

  return (
    <div className="centerize messsage-form">
      <h4>{I18n.t("user_bot.dashboards.customer.customer_message_reply_title")}</h4>
      <div>
        <textarea ref={ref} className="extend with-border" placeholder={I18n.t("common.message_content_placholder")}/>
      </div>
      <div>
        <button type="button" className="btn btn-yellow" onClick={handleSubmit} disabled={submitting}>
          {submitting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            I18n.t("action.send")
          )}
        </button>
      </div>
    </div>
  )
}

export default CustomerMessageForm
