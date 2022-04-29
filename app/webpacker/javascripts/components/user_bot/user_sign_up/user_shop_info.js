"use strict";

import React, { useState, useEffect } from "react";

import { UsersServices } from "user_bot/api";
import { RequiredLabel } from "shared/components";
import AddressView from "shared/address_view";
import I18n from 'i18n-js/index.js.erb';

export const UserShopInfo = ({props, finalView}) => {
  const [is_shop_profile_created, setShopProfile] = useState(false)
  const [is_shop_profile_checked, setCheckShopProfile] = useState(false)
  const [company_name, setCompanyName] = useState()
  const { page_title, save_btn, successful_message_html } = props.i18n.shop_info;

  useEffect(() => {
    const checkShop = async () => {
      const [error, response] = await UsersServices.checkShop()

      setShopProfile(response.data.is_shop_profile_created)
      setCheckShopProfile(true)
    }

    checkShop()
  }, [])


  const onSubmit = async (data) => {
    const [error, response] = await UsersServices.createShop({...data, company_name});

    if (response.status == 200) {
      setShopProfile(true)
    }
  }

  if (!is_shop_profile_checked) {
    return <></>
  }

  if (is_shop_profile_created) {
    return finalView
  }

  return (
    <>
      <h2 className="centerize">
        {page_title}
      </h2>
      <div className="address-form">
        <h4>
          <RequiredLabel label={I18n.t("common.shop_name")} required_label={I18n.t("common.required_label")} />
        </h4>
        <div className="field">
          <input
            value={company_name || ''}
            onChange={(e) => setCompanyName(e.target.value)}
            type="text"
          />
        </div>
      </div>
      <AddressView
        save_btn_text={save_btn}
        handleSubmitCallback={onSubmit}
      />
    </>
  )
}

export default UserShopInfo;
