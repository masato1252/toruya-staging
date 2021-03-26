"use strict";

import React, { useState } from 'react';
import Popup from 'reactjs-popup';
import { useForm  } from "react-hook-form";

import { SocialUserMessagesServices } from "user_bot/api";
import { SubmitButton } from "shared/components";

const SupportModal = ({trigger_btn, content, btn, reply}) => {
  const [submitted, setSubmitted] = useState(false)
  const { formState, register, handleSubmit} = useForm({})

  const onSubmit = async (data) => {
    console.log("data", data)
    let error, response;

    [error, response] = await SocialUserMessagesServices.create({
      data
    })

    setSubmitted(true)
  }

  return (
    <Popup
      trigger={trigger_btn}
        modal
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
