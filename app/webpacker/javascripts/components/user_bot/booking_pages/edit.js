"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import _ from "lodash";
import moment from "moment-timezone";
import ReactSelect from "react-select";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CircleButtonWithWord, TicketOptionsFields  } from "shared/components"
import { BookingPageServices } from "user_bot/api"

import BookingTimeField from "./booking_time_field";
import OverbookingRestrictionField from "./overbooking_restriction_field";
import LineSharingField from "./line_sharing_field";
import CustomerCancelRequestField from "./customer_cancel_request_field";
import OnlinePaymentEnabledField from "./online_payment_enabled_field";
import DraftField from "./draft_field";
import SocialAccountSkippableField from "./social_account_skippable_field";
import AvailableBookingDatesField from "./available_booking_dates_field";
import BookingStartAtField from "./booking_start_at_field";
import BookingEndAtField from "./booking_end_at_field";
import ShopField from "./shop_field";
import NewMenuField from "components/user_bot/booking_options/new_menu_field";

const BookingPageEdit =({props}) => {
  const i18n = props.i18n;
  const [requirement_online_service, setRequirementOnlineService] = useState(props.booking_page.requirement_online_service)

  const onSubmit = async (data) => {
    console.log(data)

    let error, response;
    if (props.attribute === "booking_time" && !data.booking_start_times && data.had_specific_booking_start_times === "true" && !data.interval) {
      return;
    }

    [error, response] = await BookingPageServices.update({
      booking_page_id: props.booking_page.id,
      data: _.assign(
        data,
        { requirement_online_service_id: requirement_online_service?.id},
        { business_owner_id: props.business_owner_id },
        { special_dates: _.includes(["event_booking", "only_special_dates_booking"], data.booking_type) ? data.special_dates : [] },
        { booking_type: data.booking_type },
        { attribute: props.attribute },
        { booking_start_times: data.had_specific_booking_start_times === "true" ? data.booking_start_times : [] }
      )
    })

    if (response.data.status == "successful") {
      window.location = response.data.redirect_to
    } else {
      toastr.error(response.data.error_message)
    }
  }

  const { register, watch, setValue, setError, control, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.booking_page,
      overbooking_restriction: String(props.booking_page.overbooking_restriction),
      line_sharing: String(props.booking_page.line_sharing),
      customer_cancel_request: String(props.booking_page.customer_cancel_request),
      online_payment_enabled: String(props.booking_page.online_payment_enabled),
      draft: String(props.booking_page.draft),
      social_account_skippable: String(props.booking_page.social_account_skippable),
      booking_type: props.booking_page.booking_type,
      had_specific_booking_start_times: String(props.booking_page.had_specific_booking_start_times),
      price_type: "regular",
      ticket_quota: 1,
      business_schedules: props.booking_page.business_schedules
    }
  });

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "name":
      case "title":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register({ required: true })} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
            <div className="field-row hint no-border"> {i18n.hint} </div>
          </>
        );
      case "greeting":
        return (
          <div className="field-row column-direction">
            <textarea autoFocus={true} ref={register} name={props.attribute} placeholder={i18n.greeting_placeholder} rows="4" colos="40" className="extend" />
          </div>
        );
      case "note":
        return (
          <div className="field-row column-direction">
            <textarea autoFocus={true} ref={register} name={props.attribute} placeholder={i18n.note_label} rows="4" colos="40" className="extend" />
          </div>
            );
      case "shop_id":
        return (
          <>
            <ShopField shop_options={props.shop_options} i18n={i18n} register={register} />
            <ErrorMessage error={errors.shop_id?.message} />
          </>
        )
      case "requirements":
        return (
          <div className="margin-around">
            <label className="text-align-left">
              <ReactSelect
                placeholder={I18n.t("common.select_a_service")}
                value={ _.isEmpty(requirement_online_service) ? "" : { label: requirement_online_service.name }}
                options={props.requirements}
                onChange={
                  (page) => {
                    setRequirementOnlineService(page.value)
                  }
                }
              />
            </label>

            {
              props.booking_page.requirement_online_service && (
                <div className="margin-around centerize">
                  <div className="field-row">
                    <strong>{props.booking_page.requirement_online_service.name}</strong>
                  </div>
                  <button
                    onClick={async () => {
                      const [error, response] = await BookingPageServices.update({
                        booking_page_id: props.booking_page.id,
                        data: _.assign( {
                          id: props.booking_page.id,
                          requirement_online_service_id: 0,
                          business_owner_id: props.business_owner_id
                        }, { attribute: props.attribute })
                      })

                      window.location = response.data.redirect_to
                    }}
                    className="btn btn-orange btn-tall margin-around m10"
                  >
                    {I18n.t("action.delete2")}
                  </button>
                </div>
              )
            }

          </div>
        )
      case "new_option_existing_menu":
        return (
          <div>
            <h3 className="header centerize">{I18n.t("settings.booking_page.form.create_a_new_option_from_existing_menu")}</h3>
            <div className="field-header">{I18n.t("settings.booking_page.form.new_option_existing_menu_menu_select_header")}</div>
            <NewMenuField
              i18n={props.i18n} register={register} watch={watch} control={control}
              menu_group_options={props.menu_group_options}
              setValue={setValue}
            />

            <h3 className="header centerize">{I18n.t("settings.booking_page.form.booking_price_setting_header")}</h3>
            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.how_much_of_this_price")}</div>
            <div className="field-row flex-start">
              <input ref={register({ required: true })} name="new_menu_price" type="tel" />
              {I18n.t("common.unit")}({I18n.t("common.tax_included")})
              {watch("price_type") == "ticket" && watch("new_menu_price") > 50000 &&
                <ErrorMessage error={I18n.t("settings.booking_option.form.form_errors.ticket_max_price_limit")} />}
            </div>
            <TicketOptionsFields
              setValue={setValue}
              watch={watch}
              register={register}
              ticket_expire_date_desc_path={props.ticket_expire_date_desc_path}
              price={watch("new_menu_price")}
            />
          </div>
        )
      case "new_option_menu":
        return (
          <div>
            <h3 className="header centerize">{I18n.t("settings.booking_page.form.create_a_new_option")}</h3>

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_name")}</div>
            <input autoFocus={true} ref={register({ required: true })} name="new_menu_name" className="extend" type="text" />

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

            <h3 className="header centerize">{I18n.t("settings.booking_page.form.booking_price_setting_header")}</h3>
            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.how_much_of_this_price")}</div>
            <div className="field-row flex-start">
              <input ref={register({ required: true })} name="new_menu_price" type="tel" />
              {I18n.t("common.unit")}({I18n.t("common.tax_included")})
              {watch("price_type") == "ticket" && watch("new_menu_price") > 50000 &&
                <ErrorMessage error={I18n.t("settings.booking_option.form.form_errors.ticket_max_price_limit")} />}
            </div>
            <TicketOptionsFields
              setValue={setValue}
              watch={watch}
              register={register}
              ticket_expire_date_desc_path={props.ticket_expire_date_desc_path}
              price={watch("new_menu_price")}
            />
          </div>
        )
      case "new_option":
        return (
          <div>
            <select autoFocus={true} className="extend" name="new_option_id" ref={register()}>
              <SelectOptions options={props.booking_page.available_booking_options} />
            </select>
            <div className="margin-around centerize">
              <button type="button" className="btn btn-yellow" onClick={handleSubmit(onSubmit)} disabled={formState.isSubmitting}>
                {formState.isSubmitting ? (
                  <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
                ) : (
                  I18n.t("user_bot.dashboards.booking_pages.form.add_a_new_option")
                )}
              </button>
            </div>
            <br />
            <hr className="border-gray-300" />
            <div className="margin-around centerize">
              <h3 className="centerize">{I18n.t("settings.booking_page.form.does_require_a_new_option")}</h3>
              <div className="my-2">
                <a href={Routes.edit_lines_user_bot_booking_page_path(props.business_owner_id, props.booking_page.id, { attribute: "new_option_existing_menu" })} className="btn btn-orange">
                  {I18n.t("settings.booking_page.form.create_a_new_option_from_existing_menu")}
                </a>
              </div>
              <a href={Routes.edit_lines_user_bot_booking_page_path(props.business_owner_id, props.booking_page.id, { attribute: "new_option_menu" })} className="btn btn-orange">
                {I18n.t("settings.booking_page.form.create_a_new_option")}
              </a>
            </div>
          </div>
        )
      case "booking_type":
        return <AvailableBookingDatesField i18n={i18n} register={register} watch={watch} control={control} setValue={setValue} />
      case "booking_time":
        return <BookingTimeField i18n={i18n} register={register} watch={watch} control={control} setValue={setValue} />
      case "booking_available_period":
        return (
          <>
            <div className="field-row flex-start">
              <select name="bookable_restriction_months" ref={register({ required: true })}>
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
                <option value="4">4</option>
                <option value="5">5</option>
                <option value="6">6</option>
                <option value="7">7</option>
                <option value="8">8</option>
                <option value="9">9</option>
                <option value="10">10</option>
                <option value="11">11</option>
                <option value="12">12</option>
              </select>
              {i18n.bookable_restriction_months_before}～
              <select name="booking_limit_day" ref={register({ required: true })}>
                <option value="0">0</option>
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
                <option value="4">4</option>
                <option value="5">5</option>
                <option value="6">6</option>
                <option value="7">7</option>
              </select>
              {i18n.booking_limit_day_before}
            </div>
            <div className="field-row">
              {I18n.t("settings.booking_page.form.booking_available_period_sample", { bookable_restriction_months_date: moment().add(watch("bookable_restriction_months"), "M").format("YYYY-MM-DD"), booking_limit_day_date: moment().add(watch("booking_limit_day"), "d").format("YYYY-MM-DD") })}
            </div>
          </>
        )
      case "start_at":
        return <BookingStartAtField i18n={i18n} register={register} watch={watch} control={control} />
      case "end_at":
        return <BookingEndAtField i18n={i18n} register={register} watch={watch} control={control} />
      case "overbooking_restriction":
        return <OverbookingRestrictionField i18n={i18n} register={register} />
      case "line_sharing":
        return <LineSharingField i18n={i18n} register={register} />
      case "customer_cancel_request":
        return <CustomerCancelRequestField i18n={i18n} register={register} watch={watch} />
      case "online_payment_enabled":
        return <OnlinePaymentEnabledField i18n={i18n} register={register} watch={watch} payment_provider_options={props.payment_provider_options} />
      case "social_account_skippable":
        return <SocialAccountSkippableField i18n={i18n} register={register} />
      case "draft":
        return <DraftField i18n={i18n} register={register} />
    }
  }

  const isSubmitDisabled = () => {
    return formState.isSubmitting ||
      (props.attribute == "new_option_existing_menu" && watch("price_type") == "ticket" && watch("new_menu_price") > 50000) ||
      (props.attribute == "new_option_menu" && watch("price_type") == "ticket" && watch("new_menu_price") > 50000)
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={Routes.lines_user_bot_booking_page_path(props.business_owner_id, props.booking_page.id)}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={i18n.top_bar_header || i18n.page_title}
            />
            <div className="field-header">{i18n.page_title}</div>
            {renderCorrespondField()}
            <BottomNavigationBar klassName="centerize transparent">
              <span></span>
              <CircleButtonWithWord
                disabled={isSubmitDisabled()}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={i18n.save}
              />
            </BottomNavigationBar>
          </div>
        </div>
        <div className="col-sm-6 px-0 hidden-xs preview-view"></div>
      </div>
    </div>
  )
}

export default BookingPageEdit;
