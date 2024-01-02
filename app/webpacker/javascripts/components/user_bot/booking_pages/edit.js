"use strict"

import React from "react";
import { useForm, Controller } from "react-hook-form";
import DayPickerInput from 'react-day-picker/DayPickerInput';
import _ from "lodash";

import { ErrorMessage, BottomNavigationBar, TopNavigationBar, SelectOptions, CircleButtonWithWord } from "shared/components"
import DateTimeFieldsRow from "shared/datetime_fields_row";
import { BookingPageServices } from "user_bot/api"

import BookingTimeField from "./booking_time_field";
import BookingLimitDayField from "./booking_limit_day_field";
import OverbookingRestrictionField from "./overbooking_restriction_field";
import LineSharingField from "./line_sharing_field";
import OnlinePaymentEnabledField from "./online_payment_enabled_field";
import DraftField from "./draft_field";
import AvailableBookingDatesField from "./available_booking_dates_field";
import BookingStartAtField from "./booking_start_at_field";
import BookingEndAtField from "./booking_end_at_field";
import ShopField from "./shop_field";

const BookingPageEdit =({props}) => {
  const i18n = props.i18n;

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
      online_payment_enabled: String(props.booking_page.online_payment_enabled),
      draft: String(props.booking_page.draft),
      booking_type: props.booking_page.booking_type,
      had_specific_booking_start_times: String(props.booking_page.had_specific_booking_start_times),
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
        break
      case "greeting":
        return (
          <div className="field-row column-direction">
            <textarea autoFocus={true} ref={register} name={props.attribute} placeholder={i18n.greeting_placeholder} rows="4" colos="40" className="extend" />
          </div>
        );
        break;
      case "note":
        return (
          <div className="field-row column-direction">
            <textarea autoFocus={true} ref={register} name={props.attribute} placeholder={i18n.note_label} rows="4" colos="40" className="extend" />
          </div>
            );
        break;
      case "shop_id":
        return (
          <>
            <ShopField shop_options={props.shop_options} i18n={i18n} register={register} />
            <ErrorMessage error={errors.shop_id?.message} />
          </>
        )
        break;
      case "new_option":
        return (
          <div>
            <select autoFocus={true} className="extend" name="new_option_id" ref={register()}>
              <option value="">{I18n.t("common.select_a_booking_option")}</option>
              <SelectOptions options={props.booking_page.available_booking_options} />
            </select>
            <hr />
            <br />
            <h3 className="centerize">OR</h3>
            <h3 className="header centerize">{I18n.t("user_bot.dashboards.booking_page_creation.create_a_new_menu")}</h3>

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_name")}</div>
            <input autoFocus={true} ref={register()} name="new_menu_name" className="extend" type="text" />

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.what_is_menu_time")}</div>
            <input autoFocus={true} ref={register()} name="new_menu_minutes" className="extend" type="tel" />

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.how_much_of_this_price")}</div>
            <input autoFocus={true} ref={register()} name="new_menu_price" className="extend" type="tel" />

            <div className="field-header">{I18n.t("user_bot.dashboards.booking_page_creation.is_menu_online")}</div>
            <label className="field-row flex-start">
              <input name="new_menu_online_state" type="radio" value="true" ref={register()} />
              {I18n.t(`user_bot.dashboards.booking_page_creation.menu_online`)}
            </label>
            <label className="field-row flex-start">
              <input name="new_menu_online_state" type="radio" value="false" ref={register()} />
              {I18n.t(`user_bot.dashboards.booking_page_creation.menu_local`)}
            </label>
          </div>
        )
        break
      case "booking_type":
        return <AvailableBookingDatesField i18n={i18n} register={register} watch={watch} control={control} setValue={setValue} />
        break;
      case "booking_time":
        return <BookingTimeField i18n={i18n} register={register} watch={watch} control={control} setValue={setValue} />
        break;
      case "booking_limit_day":
        return <BookingLimitDayField i18n={i18n} register={register} />
        break;
      case "start_at":
        return <BookingStartAtField i18n={i18n} register={register} watch={watch} control={control} />
        break;
      case "end_at":
        return <BookingEndAtField i18n={i18n} register={register} watch={watch} control={control} />
      case "overbooking_restriction":
        return <OverbookingRestrictionField i18n={i18n} register={register} />
        break;
      case "line_sharing":
        return <LineSharingField i18n={i18n} register={register} />
        break;
      case "online_payment_enabled":
        return <OnlinePaymentEnabledField i18n={i18n} register={register} />
        break;
      case "draft":
        return <DraftField i18n={i18n} register={register} />
        break;
    }
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
                disabled={formState.isSubmitting}
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
