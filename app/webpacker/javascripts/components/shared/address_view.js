"use strict";

import React, { useState, useEffect } from "react";

import { useForm } from "react-hook-form";

import useAddress from "libraries/use_address";
import { RequiredLabel, ErrorMessage } from "shared/components";
import I18n from 'i18n-js/index.js.erb';

const blankMessage = () => I18n.t("errors.messages.blank").replace(/^を/, "");

const AddressView = ({save_btn_text, show_skip_btn, handleSubmitCallback, address_details, showFieldErrors = false, externalValidator, fullWidth = false, addressRequiredLabel}) => {
  const { register, handleSubmit, watch, setValue, formState, errors } = useForm({ defaultValues: {...address_details} });
  const [is_saving, setIsSaving] = useState(false);
  const address = useAddress(watch("zip_code"))

  useEffect(() => {
    setValue("region", address?.prefecture)
    setValue("city", address?.city)
  }, [address.city])

  // 親コンポーネントの独自バリデーション（店舗名・店舗メール等）と
  // 住所側のバリデーションを同時に走らせる。両方通ったときだけ実際の送信を行う。
  // クリック直後に即座に is_saving を true にして、ボタン内スピナー表示を確実に行う。
  const handleClickSave = async (e) => {
    e && e.preventDefault && e.preventDefault();
    if (is_saving) return;
    setIsSaving(true);
    try {
      const externalValid = externalValidator ? externalValidator() : true;
      if (!externalValid) return;
      await handleSubmit(async (data) => {
        await handleSubmitCallback(data);
      })();
    } finally {
      setIsSaving(false);
    }
  }

  // 登録フロー（店舗登録など）でメールアドレス欄と幅を揃えたい場合に使用
  const fieldClass = fullWidth ? "sign-up-field" : "field";
  const inputBaseClass = fullWidth ? "form-control" : "";
  const expandedClass = fullWidth ? "" : "expanded";

  return (
    <form onSubmit={handleClickSave}>
      <div className="address-form">
        <h4>
          <RequiredLabel label={I18n.t("common.zip_code")} required_label={I18n.t("common.required_label")} />
        </h4>
        {/* 郵便番号は桁数が固定なのでフル幅にはせず、既存の幅のまま表示する */}
        <div className="field">
          <input
            ref={register({ required: true })}
            name="zip_code"
            placeholder="1234567"
            type="tel"
            className={errors.zip_code ? "error" : ""}
          />
        </div>
        {showFieldErrors && errors.zip_code && <ErrorMessage error={blankMessage()} />}
        <h4>
          <RequiredLabel label={I18n.t("common.address")} required_label={addressRequiredLabel || I18n.t("common.required_label")} />
        </h4>
        {/* 都道府県は短い名称が多いのでフル幅にはせず、既存の幅のまま表示する */}
        <div className="field">
          <input
            ref={register({ required: true })}
            name="region"
            placeholder={I18n.t("common.address_region")}
            type="text"
            className={errors.region ? "error" : ""}
          />
        </div>
        {showFieldErrors && errors.region && <ErrorMessage error={blankMessage()} />}
        <div className={fieldClass}>
          <input
            ref={register({ required: true })}
            name="city"
            placeholder={I18n.t("common.address_city")}
            type="text"
            className={`${inputBaseClass} ${expandedClass} ${errors.city ? (fullWidth ? "field-error" : "error") : ""}`.trim()}
          />
        </div>
        {showFieldErrors && errors.city && <ErrorMessage error={blankMessage()} />}
        <div className={fieldClass}>
          <input
            ref={register()}
            name="street1"
            placeholder={I18n.t("common.address_street1")}
            type="text"
            className={`${inputBaseClass} ${expandedClass}`.trim()}
          />
        </div>
        <div className={fieldClass}>
          <input
            ref={register()}
            name="street2"
            placeholder={I18n.t("common.address_street2")}
            type="text"
            className={`${inputBaseClass} ${expandedClass}`.trim()}
          />
        </div>
        <div className="action-block centerize">
          <a href="#" className="btn btn-yellow submit" onClick={handleClickSave} disabled={is_saving}>
            { is_saving ? <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i> : save_btn_text || I18n.t("action.next_step") }
          </a>
        </div>
      </div>
    </form>
  )
}

export default AddressView;