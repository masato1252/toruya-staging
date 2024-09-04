"use strict"

import React from "react";
import { useForm } from "react-hook-form";

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord } from "shared/components"
import { BookingOptionServices } from "user_bot/api"
import MenuRestrictOrderField from "./menu_restrict_order_field";
import BookingStartAtField from "components/user_bot/booking_pages/booking_start_at_field";
import BookingEndAtField from "components/user_bot/booking_pages/booking_end_at_field";
import BookingPriceField from "./booking_price_field";
import NewMenuField from "./new_menu_field";
import { responseHandler } from "libraries/helper";

const BookingOptionEdit =({props}) => {
  const i18n = props.i18n;

  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.booking_option,
      menu_restrict_order: String(props.booking_option.menu_restrict_order),
      tax_include: String(props.booking_option.tax_include),
      menu_required_time: props.editing_menu?.required_time,
      menu_id: props.editing_menu?.menu_id
    }
  });

  const onSubmit = async (data) => {
    let error, response;

    [error, response] = await BookingOptionServices.update({
      booking_option_id: props.booking_option.id,
      data: _.assign( data, { attribute: props.attribute, business_owner_id: props.business_owner_id })
    })

    responseHandler(error, response)
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "name":
      case "display_name":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register({ required: true })} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
            <div className="field-row hint no-border"> {i18n.hint} </div>
          </>
        );
      case "menu_restrict_order":
        return <MenuRestrictOrderField i18n={i18n} register={register} />
      case "price":
        return <BookingPriceField setValue={setValue} register={register} watch={watch} ticket_expire_date_desc_path={props.ticket_expire_date_desc_path}/>
      case "memo":
        return (
          <div className="field-row column-direction">
            <textarea autoFocus={true} ref={register} name={props.attribute} placeholder={i18n.note_hint} rows="4" colos="40" className="extend" />
          </div>
        );
      case "menu_required_time":
        return (
          <div className="field-row flex-start">
            {props.editing_menu?.label}
            <input ref={register({ required: true })} name="menu_required_time" type="tel" />
            <input ref={register({ required: true })} name="menu_id" type="hidden" />
            {i18n.minute}
          </div>
        );
      case "new_pure_menu":
        return (
          <div>
            <h3 className="header centerize">{I18n.t("settings.booking_option.form.create_a_new_menu")}</h3>

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_name")}</div>
            <input autoFocus={true} ref={register({ required: true })} name="new_menu_name" className="extend" type="text" />

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_time")}</div>
            <input ref={register({ required: true })} name="new_menu_minutes" className="extend" type="tel" />

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.is_menu_online")}</div>
            <label className="field-row flex-start">
              <input name="new_menu_online_state" type="radio" value="true" ref={register({ required: true })} />
              {I18n.t(`user_bot.dashboards.booking_page_creation.menu_online`)}
            </label>
            <label className="field-row flex-start">
              <input name="new_menu_online_state" type="radio" value="false" ref={register({ required: true })} />
              {I18n.t(`user_bot.dashboards.booking_page_creation.menu_local`)}
            </label>
          </div>
        )
      case "new_menu":
        return (
          <div>
            <NewMenuField
              i18n={i18n} register={register} watch={watch} control={control}
              menu_group_options={props.menu_group_options}
              setValue={setValue}
            />
            <div className="margin-around centerize">
              <button type="button" className="btn btn-yellow" onClick={handleSubmit(onSubmit)} disabled={formState.isSubmitting}>
                {formState.isSubmitting ? (
                  <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
                ) : (
                  I18n.t("user_bot.dashboards.booking_options.form.add_this_new_menu")
                )}
              </button>
            </div>
            <br />
            <br />
            <div className="field-header">{I18n.t("user_bot.dashboards.booking_options.form.add_a_new_menu")}</div>
            <div className="margin-around centerize">
              <h3 className="centerize">{I18n.t("settings.booking_option.form.does_require_a_new_menu")}</h3>
              <a href={Routes.edit_lines_user_bot_booking_option_path(props.business_owner_id, props.booking_option.id, { attribute: "new_pure_menu" })} className="btn btn-orange">
                {I18n.t("settings.booking_option.form.create_a_new_menu")}
              </a>
            </div>
          </div>
        )
      case "start_at":
        return <BookingStartAtField i18n={i18n} register={register} watch={watch} control={control} />
      case "end_at":
        return <BookingEndAtField i18n={i18n} register={register} watch={watch} control={control} />
    }
  }

  const isSubmitDisabled = () => {
    return formState.isSubmitting
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_booking_option_path(props.business_owner_id, props.booking_option.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={i18n.top_bar_header || i18n.page_title}
      />
      <div className="field-header">{i18n.page_title}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize">
        <span></span>
        <CircleButtonWithWord
          disabled={isSubmitDisabled()}
          onHandle={handleSubmit(onSubmit)}
          icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
          word={i18n.save}
        />
      </BottomNavigationBar>
    </div>
  )
}

export default BookingOptionEdit;
