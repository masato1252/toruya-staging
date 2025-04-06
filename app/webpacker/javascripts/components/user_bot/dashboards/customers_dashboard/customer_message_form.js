import React, { useState, useRef, useEffect } from "react";
import moment from "moment-timezone";
import { debounce } from "lodash";

import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { CustomerServices, CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { getMomentLocale } from "libraries/helper.js";

const CustomerMessageForm = () => {
  const { selected_customer, draft_message_content, dispatch, props } = useGlobalContext()
  const locale = props?.locale || 'ja';
  moment.locale(getMomentLocale(locale));
  const ref = useRef()
  const [submitting, setSubmitting] = useState(false)
  const [drafting, setDrafting] = useState(false)
  const [schedule_at, setScheduleAt] = useState(null)
  const [images, setImages] = useState([])
  const [imageURLs, setImageURLs] = useState([])

  const handleSubmit = async () => {
    if (submitting || (!ref.current.value && !images[0])) return;
    setSubmitting(true)
    let response = null;
    let error = null;

    [error, response] = await CustomerServices.reply_message({
      business_owner_id: selected_customer.userId,
      customer_id: selected_customer.id,
      schedule_at: schedule_at,
      message: ref.current.value,
      image: images[0]
    })
    setSubmitting(false)

    if (response?.data?.status == "successful") {
      dispatch({
        type: "REMOVE_DRAFT_CUSTOMER_MESSAGE",
        payload: {
          customer_id: selected_customer.id,
        }
      })

      if (response?.data?.redirect_to) {
        window.location.replace(response?.data?.redirect_to)
      }
      else {
        dispatch({
          type: "APPEND_NEW_MESSAGE",
          payload: {
            message: {
              message_type: "staff",
              text: ref.current.value,
              formatted_created_at: moment(Date.now()).format("llll"),
              formatted_schedule_at: schedule_at ? moment(schedule_at).format("llll") : null,
              sent: !schedule_at
            }
          }
        })
      }
    }
    else {
      toastr.error(error.response.data.error_message)
    }
  }

  useEffect(() => {
    if (images.length < 1) return;

    const newImageUrls = [];
    images.forEach(image => newImageUrls.push(URL.createObjectURL(image)));
    setImageURLs(newImageUrls)
  }, [images])

  const onImageChange = (e) => {
    setImages([...e.target.files])
  }

  const draftMessageContent = () => {
    if (draft_message_content) {
      return draft_message_content[selected_customer?.id?.toString()];
    }
    else {
      return ""
    }
  }

  const handleDraftMessage = () => {
    if (drafting) return
    if (!ref.current.value) return

    setDrafting(true)

    dispatch({
      type: "EDIT_CUSTOMER_MESSAGE",
      payload: {
        customer_id: selected_customer.id,
        message_content: ref.current.value
      }
    })

    CommonServices.create({
      url: Routes.save_draft_message_lines_user_bot_customers_path(props.business_owner_id, {format: "json"}),
      data: { draft_message_content: { ...draft_message_content, [selected_customer.id.toString()]: ref.current.value } }
    })

    toastr.success(I18n.t("common.save_draft_successfully_message"))
    setDrafting(false)
  }

  return (
    <div className="centerize message-form">
      <h4>{I18n.t("user_bot.dashboards.customer.customer_message_reply_title")}</h4>
      {props.block_toruya_message_reply ? (
        <textarea
          readOnly={true}
          onClick={() => $("#toruyaMessageReplyBlockModal").modal("show")}
          defaultValue={draftMessageContent()}
          className="extend with-border"
          placeholder={I18n.t("common.delivery_content_placeholder")}
        />
      ) : (
        <textarea
          ref={ref}
          defaultValue={draftMessageContent()}
          className="extend with-border"
          placeholder={I18n.t("common.delivery_content_placeholder")}
        />
      )}
      <div>
        <label className="flex flex-col">
          <i className='fas fa-image fa-2x'></i>
          <input type="file" accept="image/png, image/jpg, image/jpeg" onChange={onImageChange} className="display-hidden" />
          {imageURLs.map(imageSrc => <img src={imageSrc} key={imageSrc} className="w-full h-full object-contain" />)}
        </label>
      </div>
      <div className="text-left">
        <div className="margin-around m10 mt-0">
          <label>
            <input
              type="radio" name="schedule_at"
              checked={schedule_at == null}
              onChange={
                () => setScheduleAt(null)
              }
            />
            {I18n.t("common.send_now_label")}
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
        <button type="button" className="btn btn-gray mx-2" onClick={handleDraftMessage} disabled={drafting}>
          {drafting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            I18n.t("action.save_as_draft")
          )}
        </button>
        <button type="button" className="btn btn-yellow" onClick={handleSubmit} disabled={submitting}>
          {submitting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            schedule_at ? I18n.t("action.send_on_schedule") : I18n.t("action.send")
          )}
        </button>
      </div>
    </div>
  )
}

export default CustomerMessageForm
