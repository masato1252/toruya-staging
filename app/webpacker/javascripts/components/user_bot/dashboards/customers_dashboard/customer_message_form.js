import React, { useState, useRef } from "react";
import moment from "moment-timezone";

import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { CustomerServices } from "components/user_bot/api"

const CustomerMessageForm = () => {
  moment.locale('ja');
  const ref = useRef()
  const { selected_customer, dispatch } = useGlobalContext()
  const [submitting, setSubmitting] = useState(false)
  const [schedule_at, setScheduleAt] = useState(null)

  const handleSubmit = async () => {
    if (submitting || !ref.current?.value) return;
    setSubmitting(true)

    const [error, response] = await CustomerServices.reply_message({ customer_id: selected_customer.id, message: ref.current.value, schedule_at: schedule_at })
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
      <div className="text-align-left">
        <div className="margin-around m10">
          <label>
            <input
              type="radio" name="schedule_at"
              checked={schedule_at == null}
              onChange={
                () => setScheduleAt(null)
              }
            />
            Send Now
          </label>
        </div>
        <div className="margin-around m10">
          <label>
            <input
              type="radio" name="send_later"
              checked={schedule_at !== null}
              onChange={
                () => setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))
              }
            />
            <input
              type="datetime-local"
              value={schedule_at || moment().format("YYYY-MM-DDTHH:mm")}
              onClick={() => setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))}
              onChange={(e) => setScheduleAt(e.target.value) }
            />
          </label>
        </div>
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
