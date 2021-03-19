"use strict";

import React, { useState } from 'react';
import Popup from 'reactjs-popup';
import { useForm  } from "react-hook-form";

import { SocialUserMessagesServices } from "user_bot/api";

const SupportModal = () => {
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
      trigger={
        <button className="button"> Open Modal </button>}
        modal
      >
        <>
          <div className="modal-header">
            <h4 className="modal-title">
              Title
            </h4>
          </div>
          {submitted ? (
            <div className="modal-body">
              Thanks for your message, we would reply u asap.
            </div>
          )
           : (
          <>
            <div className="modal-body">
              <p className="margin-around">
                Please contact us to help you do that, write down your requirement.
              </p>
              <textarea name="content" ref={register({required: true})} className="extend" autoFocus={true} />
            </div>
            <div className="modal-footer centerize">
              <button onClick={handleSubmit(onSubmit)} type="submit" className="btn btn-yellow" disabled={formState.submitting}>
                Submit
              </button>
            </div>
          </>
          )}
        </>
    </Popup>
  )
}

export default SupportModal;
