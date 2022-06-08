"use strict";

import React, { useState } from 'react';
import Popup from 'reactjs-popup';
import { useForm  } from "react-hook-form";

import { SocialUserMessagesServices } from "user_bot/api";
import { SubmitButton } from "shared/components";
import I18n from 'i18n-js/index.js.erb';

const SupportModal = ({trigger_btn, content, btn, reply, defaultOpen, from_cancel}) => {
  const [submitted, setSubmitted] = useState(false)
  const { formState, register, handleSubmit} = useForm({})

  const onSubmit = async (data) => {
    console.log("data", data)

    await SocialUserMessagesServices.create({
      data: {
        ...data,
        content: from_cancel ? `${data.content}${I18n.t("common.cancel_request")}` : data.content
      }
    })

    setSubmitted(true)
  }

  return (
    <Popup
      trigger={trigger_btn || <></>}
      modal
      defaultOpen={defaultOpen}
      >
        <>
          {submitted ? (
            <div className="modal-body">
              <div dangerouslySetInnerHTML={{ __html: reply }} />
            </div>
          )
           : (
          <>
            <div className="modal-body">
              <p className="margin-around">
                {content}
              </p>
              <textarea name="content" ref={register({required: true})} className="extend" autoFocus={true} />
            </div>
            <div className="modal-footer centerize">
              <SubmitButton
                handleSubmit={handleSubmit(onSubmit)}
                btnWord={btn}
              />
            </div>
          </>
          )}
        </>
    </Popup>
  )
}

export default SupportModal;
