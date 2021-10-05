"use strict";

import React, { useState, useEffect } from "react";

import { useForm } from "react-hook-form";

import useAddress from "libraries/use_address";
import { RequiredLabel } from "shared/components";
import I18n from 'i18n-js/index.js.erb';

const AddressView = ({save_btn_text, handleSubmitCallback}) => {
  const { register, handleSubmit, watch, setValue, formState } = useForm();
  const { isSubmitting } = formState;
  const address = useAddress(watch("zip_code"))

  useEffect(() => {
    setValue("region", address?.prefecture)
    setValue("city", address?.city)
  }, [address.city])

  const onSubmit = (data) => {
    handleSubmitCallback(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div className="address-form">
        <h4>
          <RequiredLabel label={I18n.t("common.zip_code")} required_label={I18n.t("common.required_label")} />
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="zip_code"
            placeholder="1234567"
            type="tel"
          />
        </div>
        <h4>
          <RequiredLabel label={I18n.t("common.address")} required_label={I18n.t("common.required_label")} />
        </h4>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="region"
            placeholder={I18n.t("common.address_region")}
            type="text"
          />
        </div>
        <div className="field">
          <input
            ref={register({ required: true })}
            name="city"
            placeholder={I18n.t("common.address_city")}
            type="text"
            className="expaned"
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="street1"
            placeholder={I18n.t("common.address_street1")}
            type="text"
            className="expaned"
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="street2"
            placeholder={I18n.t("common.address_street2")}
            type="text"
            className="expaned"
          />
        </div>
        <div className="centerize">
          <a href="#" className="btn btn-yellow submit" onClick={handleSubmit(onSubmit)}>
            { isSubmitting ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : save_btn_text || I18n.t("action.next_step") }
          </a>
        </div>
      </div>
    </form>
  )
}

export default AddressView;
