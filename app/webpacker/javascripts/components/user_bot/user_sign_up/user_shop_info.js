"use strict";

import React, { useState, useEffect } from "react";
import Rails from "rails-ujs";
import { useForm } from "react-hook-form";
import postal_code from "japan-postal-code";
import axios from "axios";

export const UserShopInfo = ({props}) => {
  const { register, handleSubmit, watch, setValue, formState } = useForm();
  const { isSubmitting } = formState;
  const [is_shop_profile_created, setShopProfile] = useState(false)
  const { postcode, region, city, street1, street2, location, save_btn } = props.i18n.shop_info;

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
    const response = await axios({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: props.path.create_shop_profile,
      data: {
        zip_code: data.zip_code,
        region: data.region,
        city: data.city,
        street1: data.street1,
        street2: data.street2
      },
      responseType: "json"
    })

    if (response.status == 200) {
      setShopProfile(true)
    }
  }

  if (is_shop_profile_created) {
    return (
      <div className="whole-page-center final">
        <div>Done</div>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div className="customer-type-options">
        <h4>
          {postcode}
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="zip_code"
            placeholder={postcode}
            type="text"
            onChange={changeZipCode}
          />
        </div>
        <h4>
          {location}
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
