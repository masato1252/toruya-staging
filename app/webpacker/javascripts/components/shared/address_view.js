"use strict";

import React, { useState, useEffect } from "react";

import { useForm } from "react-hook-form";

import useAddress from "libraries/use_address";
import { RequiredLabel } from "shared/components";
import I18n from 'i18n-js/index.js.erb';

const AddressView = ({save_btn_text, show_skip_btn, handleSubmitCallback, address_details}) => {
  const { register, handleSubmit, watch, setValue, formState } = useForm({ defaultValues: {...address_details} });
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
          <span>{I18n.t("common.zip_code")}</span>
        </h4>
        <div className="field">
          <input
            ref={register()}
            name="zip_code"
            placeholder="1234567"
            type="tel"
          />
        </div>
        <h4>
          <span>{I18n.t("common.address")}</span>
        </h4>
        <div className="field">
          <input
            ref={register()}
            name="region"
            placeholder={I18n.t("common.address_region")}
            type="text"
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="city"
            placeholder={I18n.t("common.address_city")}
            type="text"
            className="expanded"
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="street1"
            placeholder={I18n.t("common.address_street1")}
            type="text"
            className="expanded"
          />
        </div>
        <div className="field">
          <input
            ref={register()}
            name="street2"
            placeholder={I18n.t("common.address_street2")}
            type="text"
            className="expanded"
          />
        </div>
        <div className="action-block centerize">
          <a href="#" className="btn btn-gray submit mr-2-5" onClick={handleSubmit(onSubmit)}>
            { isSubmitting ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : I18n.t("action.no_need_setup") }
          </a>
          <a href="#" className="btn btn-yellow submit" onClick={handleSubmit(onSubmit)}>
            { isSubmitting ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : save_btn_text || I18n.t("action.next_step") }
          </a>
        </div>
      </div>
    </form>
  )
}

export default AddressView;