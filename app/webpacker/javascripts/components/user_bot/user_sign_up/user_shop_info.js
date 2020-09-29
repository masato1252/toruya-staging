"use strict";

import React, { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import postal_code from "japan-postal-code";
import { UsersServices } from "user_bot/api";
import { RequiredLabel } from "shared/components";

export const UserShopInfo = ({props, finalView}) => {
  const { register, handleSubmit, watch, setValue, formState } = useForm();
  const { isSubmitting } = formState;
  const [is_shop_profile_created, setShopProfile] = useState(false)
  const [is_shop_profile_checked, setCheckShopProfile] = useState(false)
  const { postcode, region, city, street1, street2, location, page_title, save_btn, successful_message_html } = props.i18n.shop_info;
  const { required_label } = props.i18n;

  useEffect(() => {
    const checkShop = async () => {
      const [error, response] = await UsersServices.checkShop()

      setShopProfile(response.data.is_shop_profile_created)
      setCheckShopProfile(true)
    }

    checkShop()
  }, [])

  const changeZipCode = (e) => {
    setValue("zip_code", e.target.value)

    if (e.target.value && e.target.value.length >= 7) {
      postal_code.get(e.target.value, (address) => {
        setValue("region", address.prefecture)
        setValue("city", address.city)
      });
    }
  }

  const onSubmit = async (data) => {
    const [error, response] = await UsersServices.createShop(data);

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
    <form onSubmit={handleSubmit(onSubmit)}>
      <h2 className="centerize">
        {page_title}
      </h2>
      <div className="customer-type-options">
        <h4>
          <RequiredLabel label={postcode} required_label={required_label} />
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="zip_code"
            placeholder={postcode}
            type="tel"
            onChange={changeZipCode}
          />
        </div>
        <h4>
          <RequiredLabel label={location} required_label={required_label} />
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="region"
            placeholder={region}
            type="text"
          />
        </div>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="city"
            placeholder={city}
            type="text"
            className="expaned"
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="street1"
            placeholder={street1}
            type="text"
            className="expaned"
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="street2"
            placeholder={street2}
            type="text"
            className="expaned"
          />
        </div>
        <div className="centerize">
          <a href="#" className="btn btn-yellow submit" onClick={handleSubmit(onSubmit)}>
            { isSubmitting ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : save_btn }
          </a>
        </div>
      </div>
    </form>
  )
}

export default UserShopInfo;
