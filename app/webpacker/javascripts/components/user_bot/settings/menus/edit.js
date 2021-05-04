"use strict"

import React, { useEffect, useState } from "react";
import { useForm, Controller } from "react-hook-form";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CiricleButtonWithWord, SwitchButton } from "shared/components"
import { MenuServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const MenuEdit =({props}) => {
  const [menu_shops_options, setMenuShops] = useState(props.menu_shops_options)
  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.menu,
    }
  });

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    let error, response;

    [error, response] = await MenuServices.update({
      data: _.assign( data, { attribute: props.attribute, menu_shops: menu_shops_options })
    })

    window.location = response.data.redirect_to
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
        break;
      case "minutes":
      case "interval":
        return (
          <div className="field-row flex-start">
            <input ref={register({ required: true })} name={props.attribute} type="tel" />
            {I18n.t("common.minute")}
          </div>
        );
        break;
      case "menu_shops":
        return (
          <>
            {menu_shops_options.map((option) => {
              return (
                <div className="field-row flex-start" key={option.shop_id}>
                  <SwitchButton
                    offWord="OFF"
                    onWord="ON"
                    checked={option.checked}
                    name={option.name}
                    onChange={() => {
                      setMenuShops((menu_options) => {
                        const new_menu_options = menu_options.map((menu_option) => {
                          return menu_option.shop_id == option.shop_id ? {...menu_option, checked: !menu_option.checked} : menu_option
                        })

                        return new_menu_options
                      })
                    }}
                  />
                  {option.name}

                  {option.checked && (
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
                  )}
                </div>
              )
            })}
          </>
        )
    }
  }

  return (
    <div className="form with-top-bar">
      <input type="hidden" name="id" ref={register({ required: true })} />
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_settings_menu_path(props.menu.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t(`user_bot.dashboards.settings.menu.form.${props.attribute}_title`)}
      />
      <div className="field-header">{I18n.t(`user_bot.dashboards.settings.menu.form.${props.attribute}_subtitle`)}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize transparent">
        <span></span>
        <CiricleButtonWithWord
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
