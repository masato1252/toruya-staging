"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";

import { CommonServices } from "user_bot/api"
import { SelectOptions, BottomNavigationBar, TopNavigationBar,CircleButtonWithWord, TicketOptionsFields, CheckboxSearchFields } from "shared/components"
import { responseHandler } from "libraries/helper";
import ExistingMenuField from "components/user_bot/booking_options/existing_menu_field";

const NewMenuOptionFields = ({register}) => {
  return (
    <>
      <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_name")}</div>
      <input ref={register({ required: true })} name="new_menu_name" className="extend" type="text" />

      <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.is_menu_online")}</div>
      <label className="field-row flex-start">
        <input name="new_menu_online_state" type="radio" value="true" ref={register({ required: true })} />
        {I18n.t(`user_bot.dashboards.booking_page_creation.menu_online`)}
      </label>
      <label className="field-row flex-start">
        <input name="new_menu_online_state" type="radio" value="false" ref={register({ required: true })} />
        {I18n.t(`user_bot.dashboards.booking_page_creation.menu_local`)}
      </label>

      <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_time")}</div>
      <div className="field-row flex-start">
        <input ref={register({ required: true })} name="new_menu_minutes" type="tel" />
        {I18n.t("common.minute")}
      </div>

      <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_max_seat_number")}</div>
      <div className="field-row flex-start">
        <input ref={register({ required: true })} name="new_menu_max_seat_number" type="tel" defaultValue={1} />
        {I18n.t("common.seat_number")}
      </div>
    </>

  )
}

const NewBookingOption =({props}) => {
  const { register, watch, setValue, formState, handleSubmit, control } = useForm({ });
  // existing_booking_option, new_option_existing_menu, new_option_new_menu
  const [newBookingOptionType, setNewBookingOptionType] = useState("new_option_new_menu")

  const isSubmitDisabled = () => {
    return formState.isSubmitting
  }

  const onSubmit = async (data) => {
    console.log(data)

    // Ensure booking_page_ids is always an array, even with a single value
    if (!data.booking_page_ids) {
      data.booking_page_ids = [];
    } else if (!Array.isArray(data.booking_page_ids)) {
      data.booking_page_ids = [data.booking_page_ids];
    }

    const [error, response] = await CommonServices.create({
      url: Routes.lines_user_bot_booking_options_path(props.business_owner_id, {format: "json"}),
      data: data
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
                <a href={props.back_path || Routes.new_lines_user_bot_booking_path(props.business_owner_id)}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t("settings.booking_page.form.create_a_new_option")}
            />
            <h3 className="header centerize">{I18n.t("settings.booking_page.form.create_a_new_option")}</h3>
            <label className="field-row flex-start border-solid border-0 border-t border-b border-gray-300">
              <input
                type="radio"
                name="newBookingOptionType"
                value="new_option_new_menu"
                checked={newBookingOptionType === "new_option_new_menu"}
                onChange={() => setNewBookingOptionType("new_option_new_menu")}
              />
              {I18n.t("settings.booking_page.form.create_a_new_option")}
            </label>
            {props.support_feature_flags.support_booking_options_menu_concept && (
              <>
                <label className="field-row flex-start">
                  <input
                    type="radio"
                    name="newBookingOptionType"
                    value="new_option_existing_menu"
                    checked={newBookingOptionType === "new_option_existing_menu"}
                    onChange={() => setNewBookingOptionType("new_option_existing_menu")}
                  />
                  {I18n.t("settings.booking_page.form.create_a_new_option_from_existing_menu")}
                </label>
              </>
            )}
            <div>
              {newBookingOptionType == "new_option_new_menu" && <NewMenuOptionFields register={register} />}
              {newBookingOptionType == "new_option_existing_menu" && (
                <>
                  <h3 className="header centerize">{I18n.t("settings.booking_page.form.create_a_new_option_from_existing_menu")}</h3>
                  <ExistingMenuField
                    register={register}
                    watch={watch}
                    control={control}
                    menu_group_options={props.menu_group_options}
                    setValue={setValue}
                  />
                </>
              )}

              {(newBookingOptionType == "new_option_new_menu" || newBookingOptionType == "new_option_existing_menu") && (
                <>
                  <h3 className="header centerize">{I18n.t("settings.booking_page.form.booking_price_setting_header")}</h3>
                  <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.how_much_of_this_price")}</div>
                  <div className="field-row flex-start">
                    <input ref={register({ required: true })} name="new_menu_price" type="tel" />
                    {I18n.t("common.unit")}{props.support_feature_flags.support_tax_include_display && `(${I18n.t("common.tax_included")})`}
                    {watch("price_type") == "ticket" && watch("new_menu_price") > 50000 &&
                      <div className="warning">{I18n.t("settings.booking_option.form.form_errors.ticket_max_price_limit")}</div>}
                    {watch("new_menu_price") && watch("new_menu_price") < 100 &&
                      <div className="warning">{I18n.t("errors.selling_price_too_low")}</div>}
                  </div>
                  <TicketOptionsFields
                    setValue={setValue}
                    watch={watch}
                    register={register}
                    ticket_expire_date_desc_path={props.ticket_expire_date_desc_path}
                    price={watch("new_menu_price")}
                  />
                </>
              )}
              {props.booking_page_options.length > 0 && (
                <>
                  <div className="field-header">{I18n.t("settings.booking_page.form.booking_page_setting_header")}</div>
                  <CheckboxSearchFields
                    setValue={setValue}
                    watch={watch}
                    register={register}
                    field_name="booking_page_ids[]"
                    options={props.booking_page_options}
                    search_placeholder={I18n.t("settings.booking_page.form.search_placeholder")}
                  />
                </>
              )}
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

export default NewBookingOption;
