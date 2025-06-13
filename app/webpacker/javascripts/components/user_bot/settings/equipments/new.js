"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";

import { CommonServices } from "user_bot/api"
import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, SwitchButton } from "shared/components"
import { responseHandler } from "libraries/helper";

const NewEquipment = ({props}) => {
  const [equipmentMenus, setEquipmentMenus] = useState(props.equipment_menus_options || [])
  const { register, watch, setValue, formState, handleSubmit } = useForm({
    defaultValues: {
      quantity: 1
    }
  });

  const isSubmitDisabled = () => {
    return formState.isSubmitting
  }

  const onSubmit = async (data) => {
    console.log(data)

    const [error, response] = await CommonServices.create({
      url: Routes.lines_user_bot_settings_shop_equipments_path(props.business_owner_id, props.shop_id, {format: "json"}),
      data: {
        equipment: data,
        equipment_menus: equipmentMenus
      }
    })

    responseHandler(error, response)
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={props.back_path}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t("user_bot.dashboards.settings.equipments.new_page_title")}
            />

            <div className="field-header">{I18n.t("user_bot.dashboards.settings.equipments.new_page_header")}</div>

            <div className="field-header">{I18n.t("user_bot.dashboards.settings.equipments.name")}</div>
            <input
              autoFocus={true}
              ref={register({ required: true })}
              name="name"
              className="extend"
              type="text"
              placeholder={I18n.t("user_bot.dashboards.settings.equipments.name_placeholder")}
            />

            <div className="field-header">{I18n.t("user_bot.dashboards.settings.equipments.quantity")}</div>
            <div className="field-row flex-start">
              <input
                ref={register({ required: true, min: 1 })}
                name="quantity"
                type="number"
                min="1"
                defaultValue="1"
              />
              {I18n.t("common.object_unit")}
            </div>

            <div className="field-header">{I18n.t("user_bot.dashboards.settings.equipments.related_menus")}</div>
            {equipmentMenus.map((option) => {
              return (
                <div className="field-row flex-start" key={option.menu_id}>
                  <div className="flex justify-between w-full">
                    {option.name}
                    <SwitchButton
                      offWord="OFF"
                      onWord="ON"
                      checked={option.checked}
                      name={option.name}
                      nosize={true}
                      onChange={() => {
                        setEquipmentMenus((menu_options) => {
                          const new_menu_options = menu_options.map((menu_option) => {
                            return menu_option.menu_id == option.menu_id ? {...menu_option, checked: !menu_option.checked} : menu_option
                          })

                          return new_menu_options
                        })
                      }}
                    />
                  </div>

                  {option.checked && (
                    <div>
                      {I18n.t("user_bot.dashboards.settings.equipments.required_quantity")}
                      <input
                        type="tel"
                        value={option.required_quantity}
                        onChange={(event) => {
                          const val = event.target.value;
                          setEquipmentMenus((menu_options) => {
                            const new_menu_options = menu_options.map((menu_option) => {
                              return menu_option.menu_id == option.menu_id ? { ...menu_option, required_quantity: val } : menu_option
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
            <div className="field-row warning no-border margin-around justify-center">
              <div className="centerize" dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.settings.equipments.hint_html") }} />
            </div>

            <BottomNavigationBar klassName="centerize transparent">
              <span></span>
              <CircleButtonWithWord
                disabled={isSubmitDisabled()}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>
        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default NewEquipment;