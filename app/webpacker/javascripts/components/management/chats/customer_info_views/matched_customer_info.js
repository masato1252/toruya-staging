"use strict";

import React, { useState, useContext, useEffect } from "react";
import TextareaAutosize from 'react-autosize-textarea';

import { GlobalContext } from "context/chats/global_state";
import { zeroPad } from "libraries/helper";
import { CommonServices } from "components/user_bot/api";
import { SubmitButton } from "shared/components";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'

export default () => {
  const { selected_customer, dispatch, subscription }= useContext(GlobalContext)
  const { id, name, address }= selected_customer.shop_customer
  const [memo, setMemo] = useState(selected_customer.memo)

  const disconnectCustomer = () => {
    dispatch({
      type: "DISCONNECT_CUSTOMER",
      payload: selected_customer
    })

    subscription.perform("disconnect_customer", {
      customer_id: selected_customer.id
    })
  }

  const handleSubmit = async () => {
    if (!memo) return;

    const [error, response] = await CommonServices.create({
      url: Routes.admin_memo_path({format: "json"}),
      data: {
        customer_id: selected_customer.id, memo: memo
      }
    })

    alert("Done")
    window.location.replace(response.data.redirect_to)
  }

  useEffect(() => {
    setMemo(selected_customer.memo)
  }, [selected_customer.id])

  return (
    <>
      <div className="info">
        <p>
          {name}
        </p>
        <p>
          {address}
        </p>
        <p>
          ({zeroPad(selected_customer.shop_customer.id || 0, 7)})
        </p>
        </div>
      <button className="btn btn-orange" onClick={disconnectCustomer} >
        Disconnect
      </button>
      <TextareaAutosize value={memo || ""} onChange={(e) => setMemo(e.target.value) } className="w-full" />
      <SubmitButton
        handleSubmit={handleSubmit}
        btnWord={I18n.t("action.save")}
      />
    </>
  )
}
