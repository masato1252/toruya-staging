"use strict";

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import { ContactServices } from "components/user_bot/api"

const CustomerContactForm = ({props}) => {
  const [messageSent, setMessageSent] = useState(false)
  const { register, handleSubmit, formState } = useForm();

  const onSubmit = async (data) => {
    console.info(data)
    let error, response;

    [error, response] = await ContactServices.make_contact({
      data: _.assign( data, { social_service_user_id: props.social_customer.social_user_id })
    })

    if (response?.data.status == "successful") {
      setMessageSent(true)
    }
    else {
      alert(error?.message || response.data.error_message)
    }
  }

  if (messageSent) {
    return (
      <div className="messsage-form">
        <div className="centerize">
          <h3>{I18n.t("contact_page.message_sent.title")}</h3>
          <div dangerouslySetInnerHTML={{ __html: I18n.t("contact_page.message_sent.content_html") }} />
        </div>
      </div>
    )
  }

  return (
    <div className="messsage-form">
      <h3>{I18n.t("contact_page.message_form.title")}</h3>
      {!props.social_customer.customer_id && (
        <div>
          <h4>{I18n.t("common.name2")}</h4>
          <input
            name="last_name"
            placeholder={I18n.t("common.last_name")}
            ref={register({ required: true })}
            type="text"
          />
          <input
            name="first_name"
            placeholder={I18n.t("common.first_name")}
            ref={register({ required: true })}
            type="text"
          />
        </div>
      )}
      <div className="centerize">
        <textarea
          name="content"
          ref={register({ required: true })}
          className="extend with-border"
          placeholder={I18n.t("common.message_content_placholder")}
        />
      </div>
      <div className="centerize action-block">
        <button type="button" className="btn btn-yellow" onClick={handleSubmit(onSubmit)} disabled={formState.isSubmitting}>
          {formState.isSubmitting ? (
            <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
          ) : (
            I18n.t("action.send")
          )}
        </button>
      </div>
    </div>
  )
}

export default CustomerContactForm
