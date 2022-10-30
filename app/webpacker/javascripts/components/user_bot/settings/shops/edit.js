"use strict"

import React, { useEffect } from "react";
import { useForm, Controller } from "react-hook-form";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CircleButtonWithWord, SwitchButton } from "shared/components"
import { ShopServices } from "user_bot/api"
import useAddress from "libraries/use_address";
import I18n from 'i18n-js/index.js.erb';
import SaleDemoPage from "user_bot/sales/demo";
import LineCardPreview from "shared/line_card_preview";

const SocialAccountEdit =({props}) => {
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.shop,
    }
  });

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await ShopServices.update({
      data: _.assign( data, { attribute: props.attribute, logo: data["logo"]?.[0] })
    })

    window.location = response.data.redirect_to
  }

  const zip_code = watch("address_details[zip_code]");
  const address = useAddress(zip_code)
  const logo_url = watch("logo_url")

  useEffect(() => {
    setValue("address_details[region]", address?.prefecture)
    setValue("address_details[city]", address?.city)
  }, [address.city])

  const _handleImageChange = (e) => {
    e.preventDefault();

    let reader = new FileReader();
    let file = e.target.files[0];

    reader.onloadend = () => {
      setValue("logo_url", reader.result)
    }

    reader.readAsDataURL(file)
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "email":
      case "website":
        return (
          <div className="field-row">
            <input ref={register} name={props.attribute} type="text" className="extend" />
          </div>
        );
      break;
      case "phone_number":
        return (
          <>
            <div className="field-row">
              <input ref={register} name={props.attribute} type="text" className="extend" />
            </div>
            <p class="desc margin-around centerize">
              <div dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.settings.shop.phone_number_hint_html") }} />
            </p>
          </>
        );
      case "logo":
        return (
          <>
            <div className="field-row justify-center">
              <div className="margin-around">
                <input type="hidden" name="logo_url" ref={register} />
                <img src={logo_url} className="logo" />
              </div>
              <input ref={register} onChange={_handleImageChange} type="file" name="logo" accept="image/png,image/gif" />
              <p className="margin-around desc centerize">
                {I18n.t("user_bot.dashboards.settings.shop.logo_limit_description")}
              </p>
            </div>
            <p class="desc margin-around centerize">
              {I18n.t("user_bot.dashboards.settings.company.info_hint")}
            </p>
          </>
        )
        break;
      case "name":
        return (
          <>
            <div className="field-row">
              {I18n.t("common.shop_name")}
              <input ref={register({ required: true })} name="name" type="text" />
            </div>
            <div className="field-row">
              {I18n.t("common.short_shop_name")}
              <input ref={register({ required: true })} name="short_name" type="text" />
            </div>
            <p class="desc margin-around centerize">
              {I18n.t("user_bot.dashboards.settings.company.info_hint")}
            </p>
          </>
        );
        break;
      case "address":
        return (
          <>
            <div className="field-row">
              {I18n.t("common.zip_code")}
              <input
                ref={register({ required: true })}
                name="address_details[zip_code]"
                placeholder="1234567"
                type="tel"
              />
            </div>
            <div className="field-row">
              {I18n.t("common.address_region")}
              <input
                ref={register({ required: true })}
                  name="address_details[region]"
                type="text"
              />
            </div>
            <div className="field-row">
              {I18n.t("common.address_city")}
              <input
                ref={register({ required: true })}
                name="address_details[city]"
                type="text"
              />
            </div>
            <div className="field-row">
              {I18n.t("common.address_street1")}
              <input
                ref={register}
                name="address_details[street1]"
                type="text"
              />
            </div>
            <div className="field-row">
              {I18n.t("common.address_street2")}
              <input
                ref={register}
                name="address_details[street2]"
                type="text"
              />
            </div>
            <p class="desc margin-around centerize">
              {I18n.t("user_bot.dashboards.settings.company.info_hint")}
            </p>
          </>
        )
        break
      case "holiday_working":
        return (
          <div className="field-row">
            {I18n.t("user_bot.dashboards.settings.business_schedules.japanese_holiday_label")}
            <Controller
              control={control}
              name='holiday_working'
              defaultValue={watch("holiday_working")}
              render={({ onChange, value }) => (
                <SwitchButton
                  offWord="CLOSED"
                  onWord="OPEN"
                  name="holiday_working"
                  checked={value}
                  onChange={() => {
                    onChange(!value)
                  }}
                />
              )}
            />
          </div>
        );
        break
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <input type="hidden" name="id" ref={register({ required: true })} />
            <TopNavigationBar
              leading={
                <a href={props.previous_path}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={props.title}
            />
            <div className="field-header">{props.header}</div>
            {renderCorrespondField()}
            <BottomNavigationBar klassName="centerize transparent">
              <span></span>
              <CircleButtonWithWord
                disabled={formState.isSubmitting}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>

        <div className="col-sm-6 px-0 hidden-xs preview-view">
          {['name'].includes(props.attribute) && (
            <div class="fake-mobile-layout">
              <SaleDemoPage
                shop={{...props.shop, name: watch("short_name") || watch("name")}}
              />
            </div>
          )}
          {['phone_number'].includes(props.attribute) && (
            <div className="fake-mobile-layout">
              <div className="line-chat-background">
                <LineCardPreview
                  title={I18n.t("line.bot.messages.contact.contact_us")}
                  desc={I18n.t("line.bot.messages.contact.contact_us_with_text_or_phone")}
                  actions={
                    <>
                      <div className="btn btn-gray btn-extend my-2">
                        {I18n.t("action.send_message")}
                      </div>
                      {watch("phone_number")?.length ? (
                        <div className="btn btn-gray btn-extend">
                          {I18n.t("action.call")}
                        </div>) :
                          <></>
                      }
                    </>
                  }
                />
              </div>
            </div>
          )}
          {['logo'].includes(props.attribute) && (
            <div class="fake-mobile-layout">
              <SaleDemoPage
                shop={{...props.shop, logo_url: watch("logo_url")}}
              />
            </div>
          )}
          {['address'].includes(props.attribute) && (
            <div class="fake-mobile-layout">
              <SaleDemoPage
                shop={{...props.shop, address: `〒${watch('address_details[zip_code]')}${watch('address_details[region]')}${watch('address_details[city]')}${watch('address_details[street1]')}${watch('address_details[street2]')}`}}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default SocialAccountEdit;
