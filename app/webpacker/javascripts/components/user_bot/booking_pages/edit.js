"use strict"

import React from "react";
import { useForm, Controller } from "react-hook-form";
import DayPickerInput from 'react-day-picker/DayPickerInput';
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, SelectOptions, CiricleButtonWithWord } from "shared/components"
import DateTimeFieldsRow from "shared/datetime_fields_row";
import { BookingPageServices } from "user_bot/api"

import BookingIntervalField from "./booking_interval_field";
import BookingLimitDayField from "./booking_limit_day_field";
import OverbookingRestrictionField from "./overbooking_restriction_field";
import LineSharingField from "./line_sharing_field";
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

    [error, response] = await BookingPageServices.update({
      booking_page_id: props.booking_page.id,
      data: _.assign( data, { special_dates: data.had_special_date == "true" ? data.special_dates : [] }, { attribute: props.attribute })
    })

    window.location = response.data.redirect_to
  }

  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.booking_page,
      overbooking_restriction: String(props.booking_page.overbooking_restriction),
      line_sharing: String(props.booking_page.line_sharing),
      draft: String(props.booking_page.draft),
      had_special_date: String(props.booking_page.had_special_date)
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
            <div className="field-row hint"> {i18n.hint} </div>
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
        return <ShopField shop_options={props.shop_options} i18n={i18n} register={register} />
        break;
      case "new_option":
        return (
          <select autoFocus={true} className="extend" name="new_option" ref={register({ required: true })}>
            <SelectOptions options={props.booking_page.available_booking_options} />
          </select>
        )
        break
      case "special_dates":
        return <AvailableBookingDatesField i18n={i18n} register={register} watch={watch} control={control} setValue={setValue} />
        break;
      case "interval":
        return <BookingIntervalField i18n={i18n} register={register} />
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
      case "draft":
        return <DraftField i18n={i18n} register={register} />
        break;
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_booking_page_path(props.booking_page.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={i18n.title}
      />
      <div className="field-header">{i18n.title}</div>
      {renderCorrespondField()}
      <BottomNavigationBar klassName="centerize">
        <span></span>
        <CiricleButtonWithWord
          onHandle={handleSubmit(onSubmit)}
          icon={<i className="fa fa-save fa-2x"></i>}
          word={i18n.save}
        />
      </BottomNavigationBar>
    </div>
  )
}

export default BookingPageEdit;
