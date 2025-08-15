"use strict"

import React, { useEffect, useState } from "react";
import { useForm, Controller } from "react-hook-form";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, SwitchButton } from "shared/components"
import { MenuServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const MenuEdit =({props}) => {
  const [menu_shops_options, setMenuShops] = useState(props.menu_shops_options)
  const [menu_staffs_options, setMenuStaffs] = useState(props.menu_staffs_options)
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.menu,
      online: String(props.menu.online)
    }
  });
  const online = watch("online")

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await MenuServices.update({
      data: _.assign( data, { attribute: props.attribute, menu_shops: menu_shops_options, menu_staffs: menu_staffs_options, business_owner_id: props.business_owner_id, back_path: props.back_path })
    })

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to
    }
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "name":
        return (
          <>
            <div className="field-row">
              {I18n.t("user_bot.dashboards.settings.menu.name")}
              <input ref={register({ required: true })} name="name" type="text" />
            </div>
            <div className="field-row">
              {I18n.t("user_bot.dashboards.settings.menu.short_name")}
              <input ref={register({ required: true })} name="short_name" type="text" />
            </div>
          </>
        );
      case "minutes":
      case "interval":
        return (
          <div className="field-row flex-start">
            <input ref={register({ required: true })} name={props.attribute} type="tel" />
            {I18n.t("common.minute")}
          </div>
        );
      case "min_staffs_number":
        return (
          <>
            <div className="field-row flex-start">
              <input ref={register({ required: true, min: 0 })} name="min_staffs_number" type="tel" />
              {I18n.t("user_bot.dashboards.settings.menu.form.min_staffs_number_unit")}
            </div>
            <div className="margin-around justify-center warning">
              <div className="centerize" dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.settings.menu.form.min_staffs_number_hint") }} />
            </div>
          </>
        );
      case "online":
        return (
          <>
            <label className="field-row flex-start">
              <input name="online" type="radio" value="false" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.settings.menu.methods.local")}
            </label>
            <label className="field-row flex-start">
              <input name="online" type="radio" value="true" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.settings.menu.methods.online")}
            </label>
          </>
        )
      case "menu_shops":
        return (
          <>
            {menu_shops_options.map((option) => {
              return (
                <div className="field-row flex-start" key={option.shop_id}>
                  {false && (
                    <div className="flex justify-between w-full">
                      {option.name}
                      <SwitchButton
                        offWord="OFF"
                        onWord="ON"
                        checked={option.checked}
                        name={option.name}
                        nosize={true}
                        onChange={() => {
                          setMenuShops((menu_options) => {
                            const new_menu_options = menu_options.map((menu_option) => {
                              return menu_option.shop_id == option.shop_id ? {...menu_option, checked: !menu_option.checked} : menu_option
                            })

                            return new_menu_options
                          })
                        }}
                      />
                    </div>
                  )}

                  {option.checked && (
                    <div>
                      {I18n.t("user_bot.dashboards.settings.menu.full_seat_number_title")}
                      <input
                        type="tel"
                        value={option.max_seat_number}
                        onChange={(event) => {
                          const val = event.target.value;
                          setMenuShops((menu_options) => {
                            const new_menu_options = menu_options.map((menu_option) => {
                              return menu_option.shop_id == option.shop_id ? {...menu_option, max_seat_number: val} : menu_option
                            })

                            return new_menu_options
                          })
                        }}
                      />
                    </div>
                  )}
                </div>
              )
            })}
            <div className="field-row hint no-border margin-around justify-center">
              <div className="centerize" dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.settings.menu.form.hint") }} />
            </div>
          </>
        )
      case "menu_staffs":
        return (
          <>
            {menu_staffs_options.map((option) => {
              return (
                <div className="field-row flex-start" key={option.shop_id}>
                  <div className="flex justify-between w-full">
                    {option.name}
                    <SwitchButton
                      offWord="OFF"
                      onWord="ON"
                      checked={option.checked}
                      name={option.name}
                      nosize={true}
                      onChange={() => {
                        setMenuStaffs((menu_options) => {
                          const new_menu_options = menu_options.map((menu_option) => {
                            return menu_option.staff_id == option.staff_id ? {...menu_option, checked: !menu_option.checked} : menu_option
                          })

                          return new_menu_options
                        })
                      }}
                    />
                  </div>

                  {option.checked && (
                    <div>
                      {I18n.t("user_bot.dashboards.settings.menu.form.menu_staffs_max_customers")}
                      <input
                        type="tel"
                        value={option.max_customers}
                        onChange={(event) => {
                          const val = event.target.value;
                          setMenuStaffs((menu_options) => {
                            const new_menu_options = menu_options.map((menu_option) => {
                              return menu_option.staff_id == option.staff_id ? { ...menu_option, max_customers: val } : menu_option
                            })

                            return new_menu_options
                          })
                        }}
                      />
                    </div>
                  )}
                </div>
              )
            })}
            <div className="field-row hint no-border margin-around justify-center">
              <div className="centerize" dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.settings.menu.form.hint") }} />
            </div>
          </>
        )
    }
  }

  return (
    <div className="form with-top-bar">
      <input type="hidden" name="id" ref={register({ required: true })} />
      <TopNavigationBar
        leading={
          <a href={props.back_path || Routes.lines_user_bot_settings_menu_path(props.business_owner_id, props.menu.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t(`user_bot.dashboards.settings.menu.form.${props.attribute}_title`)}
      />
      <div className="field-header">{I18n.t(`user_bot.dashboards.settings.menu.form.${props.attribute}_subtitle`)}</div>
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
  )
}

export default MenuEdit;
