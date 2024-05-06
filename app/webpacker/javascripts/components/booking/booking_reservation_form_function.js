"use strict";

import React, { useState } from "react";
import moment from 'moment-timezone';
import axios from "axios";
import _ from "lodash";
import arrayMove from "array-move"

import OwnerWarning from "./owner_warning";
import DraftWarning from "./draft_warning";
import BookingHeader from "./booking_header";
// import CustomerAddressView from "./customer_address_view";
import BookingDownView from "./booking_down_view";
import ChargingView from "./charging_view";
import BookingFailedArea from "./booking_failed_area";
import BookingEndedView from "./booking_ended_view";
import BookingStartedYetView from "./booking_started_yet_view";
import SelectedBookingOption from "./selected_booking_option";
import BookingCalendar from "./booking_calendar";
import BookingDateTime from "./booking_date_time";
import SocialCustomerLogin from "./social_customer_login";
import RegularCustomersOption from "./regular_customers_option";
import CurrentCustomerInfo from "./current_customer_info";
import CustomerInfoModal from "./customer_info_modal";
import CustomerInfoFieldModel from "./customer_info_field_modal";
import BookingReservationButton from "./booking_reservation_button";
import BookingFlowOptions from "./booking_flow_options";
import BookingOptionFirstFlow from "./booking_option_first_flow";
import BookingDateFirstFlow from "./booking_date_first_flow";

const BookingReservationFormFunction = ({props}) => {
  moment.locale("ja");
  let findCustomerCall;

  const [booking_reservation_form_values, set_booking_reservation_form_values] = useState(props.booking_reservation_form)
  const [booking_reservation_form_errors, set_booking_reservation_form_errors] = useState({})

  const isCustomerAddressFilled = () => {
    return true
    // const { customer_info } = booking_reservation_form_values
    //
    // return customer_info.address_details?.zip_code && customer_info.address_details?.region && customer_info.address_details?.city
  }

  const selected_booking_option = () => {
    const { booking_options, booking_option_id } = booking_reservation_form_values;

    return _.find(booking_options, (booking_option) => {
      return booking_option.id === booking_option_id
    })
  }

  const isPremiumService = () => {
    return !selected_booking_option()?.is_free
  }

  const handleAddressCallback = (address) => {
    const { is_filling_address } = booking_reservation_form_values
    set_booking_reservation_form_values(prev => ({...prev, customer_info: {...prev.customer_info, address_details: address }}))

    if (is_filling_address) {
      handleSubmit()
    }
  }

  const resetValues = (fields) => {
    fields.forEach((field) => {
      let resetValue = null;

      switch (field) {
        case "customer_info":
          resetValue = {}
          break;
        case "booking_times":
          resetValue = []
          break;
      }

    set_booking_reservation_form_values(prev => ({...prev,  [field]: resetValue}))
    })

    set_booking_reservation_form_values(prev => ({...prev,  booking_failed: null}))
    return {};
  }

  const resetFlowValues = async () => {
    resetValues([
      "booking_option_id",
      "booking_date",
      "booking_at",
      "booking_times"
    ])
  }

  const resetBookingFailedValues = () => {
    const { is_single_option } = props.booking_page

    if (is_single_option) {
      resetValues([
        "booking_date",
        "booking_at",
        "booking_times"
      ])
    }
    else {
      resetFlowValues();
    }
  }

  const fetchBookingTimes = async (date) => {
    scrollToTarget("times_header")
    set_booking_reservation_form_values(prev => ({...prev, booking_date: date, is_fetching_booking_time: true}));

    const response = await axios({
      method: "GET",
      url: props.calendar.dateSelectedCallbackPath,
      params: {
        date: date,
        booking_option_id: booking_reservation_form_values.booking_option_id
      },
      responseType: "json"
    })

    set_booking_reservation_form_values(prev => ({...prev, is_fetching_booking_time: null}));

    if (Object.keys(response.data.booking_times).length) {
      set_booking_reservation_form_values(prev => ({...prev, booking_times: response.data.booking_times}));
    } else {
      set_booking_reservation_form_values(prev => ({...prev, booking_times: []}));
    }

    setTimeout(() => scrollToTarget("footer"), 1000)
  }

  const setBookingTimeAt = async (time) => {
    set_booking_reservation_form_values(prev => ({...prev, booking_at: time }))
    scrollToSelectedTarget()
  }

  const scrollToTarget = (target_id) => {
    if (document.getElementById(target_id)) {
      document.getElementById(target_id).scrollIntoView();
    }
  }

  const scrollToSelectedTarget = () => {
    const { booking_flow } = booking_reservation_form_values;
    let scroll_to;

    if (booking_flow === "booking_date_first") {
      scroll_to = "selected-booking-datetime"
    }
    else if (booking_flow === "booking_option_first") {
      scroll_to = "selected-booking-option"
    }

    scrollToTarget(scroll_to);
  }

  const isBookingFlowEnd = () => {
    const { booking_option_id, booking_date, booking_at } = booking_reservation_form_values;

    return booking_option_id && booking_date && booking_at
  }

  const isSocialLoginChecked = () => {
    const { social_user_id, customer_without_social_account } = booking_reservation_form_values

    return !props.social_account_login_required || social_user_id || customer_without_social_account
  }

  const isEnoughCustomerInfo = () => {
    const {
      customer_info,
      customer_last_name,
      customer_first_name,
      customer_phonetic_last_name,
      customer_phonetic_first_name,
      customer_phone_number,
      found_customer
    } = booking_reservation_form_values;

    return (found_customer && customer_info && customer_info.id) || (
      customer_last_name &&
      customer_first_name &&
      customer_phonetic_last_name &&
      customer_phonetic_first_name &&
      customer_phone_number
    )
  }

  const isCustomerTrusted = () => {
    const { found_customer, use_default_customer, booking_code } = booking_reservation_form_values;

    return (use_default_customer && isEnoughCustomerInfo()) || (found_customer != null && booking_code && booking_code.passed)
  }

  const sorted_booking_options = (booking_options, last_selected_option_id) => {
    const matched_index = booking_options.findIndex(option => option.id === last_selected_option_id);

    if (matched_index > 0) {
      return arrayMove(booking_options, matched_index, 0);
    }
    else {
      return booking_options
    }
  }

  const selectBookingOption = async (booking_option_id) => {
    set_booking_reservation_form_values(prev => ({...prev, booking_option_id: booking_option_id}))
    scrollToSelectedTarget()
  }

  const validateData = async () => {
    const { customer_first_name, customer_last_name, customer_phonetic_last_name, customer_phonetic_first_name, customer_phone_number } = booking_reservation_form_values;

    if (!customer_last_name) {
      set_booking_reservation_form_values(prev => ({...prev, errors: { ...prev.errors, customer_last_name_failed_message: `${props.i18n.last_name}${props.i18n.errors.required}`}}))
    }

    if (!customer_first_name) {
      set_booking_reservation_form_values(prev => ({...prev, errors: { ...prev.errors, customer_first_name_failed_message: `${props.i18n.first_name}${props.i18n.errors.required}`}}))
    }

    if (!customer_phone_number) {
      set_booking_reservation_form_values(prev => ({...prev, errors: { ...prev.errors, customer_phone_number_failed_message: `${props.i18n.phone_number}${props.i18n.errors.required}`}}))
    }

    if (!customer_phonetic_first_name || !customer_phonetic_last_name) {
      set_booking_reservation_form_values(prev => ({...prev, errors: { ...prev.errors, customer_phonetic_name_failed_message: props.i18n.message.customer_phonetic_name_failed_message}}))
    }

    if (customer_first_name && customer_last_name && customer_phonetic_last_name && customer_phonetic_first_name && customer_phone_number) {
      set_booking_reservation_form_values(prev => ({...prev, errors: {}}))
    }
  }

  const findCustomer = async (event) => {
    event.preventDefault();
    await validateData()
    const { customer_first_name, customer_last_name, customer_phonetic_last_name, customer_phonetic_first_name, customer_phone_number } = booking_reservation_form_values;

    if (!(customer_first_name && customer_last_name && customer_phone_number && customer_phonetic_last_name && customer_phonetic_first_name)) {
      return;
    }

    if (findCustomerCall) {
      return;
    }

    set_booking_reservation_form_values(prev => ({
      ...prev,
      is_finding_customer: true,
      errors: {}
    }))

    findCustomerCall = "loading";

    const response = await axios({
      method: "GET",
      url: props.path.find_customer,
      params: {
        customer_first_name: customer_first_name,
        customer_last_name: customer_last_name,
        customer_phone_number: customer_phone_number,
      },
      responseType: "json"
    })

    const {
      customer_info,
      last_selected_option_id,
      booking_code,
    } = response.data;

    set_booking_reservation_form_values(prev => ({
      ...prev,
      customer_info: customer_info,
      present_customer_info: customer_info,
      found_customer: Object.keys(customer_info).length ? true : false,
      last_selected_option_id: last_selected_option_id,
      is_finding_customer: null,
      booking_code: booking_code,
      use_default_customer: false,
      booking_code: {
        ...prev.booking_code,
        passed: booking_code.passed
      }
    }))

    findCustomerCall = null;
  }

  const handleSubmit = async () => {
    const { is_paying_booking, stripe_token, square_token, bookingReservationLoading } = booking_reservation_form_values

    if (bookingReservationLoading) return;
    if (is_paying_booking && !stripe_token && !square_token) return;

    set_booking_reservation_form_values(prev => ({...prev, submitting: true, bookingReservationLoading: true}))
    // this.bookingReserationLoading = "loading";

    axios.interceptors.response.use(function (response) {
      // Any status code that lie within the range of 2xx cause this function to trigger
      // Do something with response data
      return response;
    }, function (error) {
      // Any status codes that falls outside the range of 2xx cause this function to trigger
      // Do something with response error
      console.log(error)
      return Promise.reject(error);
    });

    try {
      const response = await axios({
        method: "POST",
        url: props.path.save,
        data: _.merge(
          _.pick(
            props.payment_solution,
            "square_location_id"
          ),
          _.pick(
            booking_reservation_form_values.booking_code,
            "uuid",
          ),
          _.pick(
            booking_reservation_form_values,
            "stripe_token",
            "square_token",
            "booking_option_id",
            "booking_date",
            "booking_at",
            "customer_first_name",
            "customer_last_name",
            "customer_phonetic_last_name",
            "customer_phonetic_first_name",
            "customer_phone_number",
            "customer_info",
            "present_customer_info",
            "social_user_id",
            "sale_page_id"
          ),
        ),
        responseType: "json"
      })

      // this.bookingReserationLoading = null;
      set_booking_reservation_form_values(prev => ({...prev, submitting: false, bookingReservationLoading: false}))

      const { status, errors } = response.data;

      if (status === "successful") {
        set_booking_reservation_form_values(prev => ({...prev, is_done: true}))
      }
      else if (status === "failed") {
        set_booking_reservation_form_values(prev => ({...prev, booking_failed: true}))

        if (errors) {
          set_booking_reservation_form_values(prev => ({...prev, errors: { ...prev.errors, booking_failed_message: errors.message}}))
          setTimeout(() => scrollToTarget("footer"), 200)
        }
      }
      else if (status === "invalid_authenticity_token") {
        location.reload()
      }
    }
    catch(error) {
      debugger
      location.reload()
    }
  }

  const renderBookingFlow = () => {
    const { is_single_option, is_started, is_ended } = props.booking_page
    const { is_done, is_paying_booking, is_filling_address } = booking_reservation_form_values

    // if (is_filling_address && isPremiumService() && !isCustomerAddressFilled()) {
    //   return (
    //     <CustomerAddressView
    //       handleAddressCallback={handleAddressCallback}
    //       address={booking_reservation_form_values.customer_info.address_details}
    //     />
    //   )
    // }

    if (is_done) {
      // if (isPremiumService() && !isCustomerAddressFilled()) {
      //   return (
      //     <CustomerAddressView
      //       handleAddressCallback={handleAddressCallback}
      //       address={booking_reservation_form_values.customer_info.address_details}
      //     />
      //   )
      // }

      return <BookingDownView i18n={props.i18n} social_account_add_friend_url={props.social_account_add_friend_url} />
    }

    if (is_paying_booking) {
      // if (isPremiumService() && !isCustomerAddressFilled()) {
      //   return (
      //     <CustomerAddressView
      //       handleAddressCallback={handleAddressCallback}
      //       address={booking_reservation_form_values.customer_info.address_details}
      //     />
      //   )
      // }

      return (
        <div>
          <ChargingView
            booking_date={booking_reservation_form_values.booking_date}
            booking_at={booking_reservation_form_values.booking_at}
            time_from={props.i18n.time_from}
            payment_solution={props.payment_solution}
            handleTokenCallback={async (token) => {
              const token_name = payment_solution.solution == "stripe_connect" ? "stripe_token" : "square_token"
              set_booking_reservation_form_values(prev => ({...prev, [token_name]: token }))
              handleSubmit()
            }}
            product_name={selected_booking_option().name}
            booking_details={`${moment.tz(`${booking_reservation_form_values.booking_date} ${booking_reservation_form_values.booking_at}`, "YYYY-MM-DD HH:mm", props.timezone).format("llll")} ${props.i18n.time_from}`}
            product_price={selected_booking_option().price}
          />
          <BookingFailedArea
            booking_failed={booking_reservation_form_values.booking_failed}
            booking_failed_message={booking_reservation_form_values.errors?.booking_failed_message}
            i18n={props.i18n}
            is_single_option={is_single_option}
            resetBookingFailedValues={resetBookingFailedValues}
          />
        </div>
      )
    }

    if (is_ended) {
      return <BookingEndedView social_account_add_friend_url={props.social_account_add_friend_url} />
    }

    if (!is_started) {
      return <BookingStartedYetView start_at={props.booking_page.start_at} social_account_add_friend_url={props.social_account_add_friend_url} />
    }

    if (is_single_option) {
      return (
        <div>
          <SelectedBookingOption
            i18n={props.i18n}
            booking_reservation_form_values={booking_reservation_form_values}
            booking_option_value={selected_booking_option()}
            timezone={props.timezone}
          />
          <BookingCalendar
            i18n={props.i18n}
            booking_reservation_form_values={booking_reservation_form_values}
            calendar={props.calendar}
            fetchBookingTimes={fetchBookingTimes}
            setBookingTimeAt={setBookingTimeAt}
          />
          {isBookingFlowEnd() && (
            <BookingDateTime
              i18n={props.i18n}
              booking_reservation_form_values={booking_reservation_form_values}
              timezone={props.timezone}
              resetValuesCallback={() => resetValues(["booking_date", "booking_at", "booking_times"])}
            />
          )}
          {isBookingFlowEnd() && !isSocialLoginChecked() && (
            <SocialCustomerLogin
              booking_reservation_form_values={booking_reservation_form_values}
              social_account_login_url={props.social_account_login_url}
            />
          )}
          {isBookingFlowEnd() && isSocialLoginChecked() && (
            <RegularCustomersOption
              set_booking_reservation_form_values={set_booking_reservation_form_values}
              booking_reservation_form_values={booking_reservation_form_values}
              isCustomerTrusted={isCustomerTrusted()}
              i18n={props.i18n}
              findCustomer={findCustomer}
            />
          )}
          {isBookingFlowEnd() && isSocialLoginChecked() && (
            <CurrentCustomerInfo
              booking_reservation_form_values={booking_reservation_form_values}
              i18n={props.i18n}
              isCustomerTrusted={isCustomerTrusted()}
              not_me_callback={() => {
                set_booking_reservation_form_values(prev => ({...prev, found_customer: null, use_default_customer: false}))
              }}
            />
          )}
          {isSocialLoginChecked() && (
            <BookingReservationButton
              set_booking_reservation_form_values={set_booking_reservation_form_values}
              booking_reservation_form_values={booking_reservation_form_values}
              i18n={props.i18n}
              booking_page={props.booking_page}
              payment_solution={props.payment_solution}
              isBookingFlowEnd={isBookingFlowEnd()}
              isEnoughCustomerInfo={isEnoughCustomerInfo()}
              isCustomerTrusted={isCustomerTrusted()}
              isPremiumService={isPremiumService()}
              isCustomerAddressFilled={isCustomerAddressFilled()}
              handleSubmit={handleSubmit}
              is_single_option={is_single_option}
              resetBookingFailedValues={resetBookingFailedValues}
            />
          )}
        </div>
      )
    } else {
      return (
        <div>
          <BookingFlowOptions
            set_booking_reservation_form_values={set_booking_reservation_form_values}
            booking_reservation_form_values={booking_reservation_form_values}
            i18n={props.i18n}
          />
          <BookingOptionFirstFlow
            booking_reservation_form_values={booking_reservation_form_values}
            i18n={props.i18n}
            sorted_booking_options={sorted_booking_options}
            selectBookingOption={selectBookingOption}
            timezone={props.timezone}
            selected_booking_option={selected_booking_option()}
            resetFlowValues={resetFlowValues}
            calendar={props.calendar}
            fetchBookingTimes={fetchBookingTimes}
            setBookingTimeAt={setBookingTimeAt}
            resetValues={resetValues}
          />
          <BookingDateFirstFlow
            booking_reservation_form_values={booking_reservation_form_values}
            i18n={props.i18n}
            calendar={props.calendar}
            fetchBookingTimes={fetchBookingTimes}
            setBookingTimeAt={setBookingTimeAt}
            timezone={props.timezone}
            resetValues={resetValues}
            selected_booking_option={selected_booking_option()}
            selectBookingOption={selectBookingOption}
            sorted_booking_options={sorted_booking_options}
          />
          {isBookingFlowEnd() && !isSocialLoginChecked() && (
            <SocialCustomerLogin
              booking_reservation_form_values={booking_reservation_form_values}
              social_account_login_url={props.social_account_login_url}
            />
          )}
          {isBookingFlowEnd() && isSocialLoginChecked() && (
            <RegularCustomersOption
              set_booking_reservation_form_values={set_booking_reservation_form_values}
              booking_reservation_form_values={booking_reservation_form_values}
              isCustomerTrusted={isCustomerTrusted()}
              i18n={props.i18n}
              findCustomer={findCustomer}
            />
          )}
          {isBookingFlowEnd() && isSocialLoginChecked() && (
            <CurrentCustomerInfo
              booking_reservation_form_values={booking_reservation_form_values}
              i18n={props.i18n}
              isCustomerTrusted={isCustomerTrusted()}
              not_me_callback={() => {
                set_booking_reservation_form_values(prev => ({...prev, found_customer: null, use_default_customer: false}))
              }}
            />
          )}
          {isSocialLoginChecked() && (
            <BookingReservationButton
              set_booking_reservation_form_values={set_booking_reservation_form_values}
              booking_reservation_form_values={booking_reservation_form_values}
              i18n={props.i18n}
              booking_page={props.booking_page}
              payment_solution={props.payment_solution}
              isBookingFlowEnd={isBookingFlowEnd()}
              isEnoughCustomerInfo={isEnoughCustomerInfo()}
              isCustomerTrusted={isCustomerTrusted()}
              isPremiumService={isPremiumService()}
              isCustomerAddressFilled={isCustomerAddressFilled()}
              handleSubmit={handleSubmit}
              is_single_option={is_single_option}
              resetBookingFailedValues={resetBookingFailedValues}
            />
          )}
        </div>
      )
    }
  }

  return (
    <>
      <form onSubmit={handleSubmit}>
        <OwnerWarning i18n={props.i18n} is_shop_owner={props.is_shop_owner} is_done={booking_reservation_form_values.is_done} />
        <DraftWarning i18n={props.i18n} booking_page={props.booking_page} />
        <BookingHeader booking_page={props.booking_page} is_done={booking_reservation_form_values.is_done} />
        {renderBookingFlow()}
      </form>

      <CustomerInfoModal
        set_booking_reservation_form_values={set_booking_reservation_form_values}
        booking_reservation_form_values={booking_reservation_form_values}
        i18n={props.i18n}
      />
      <CustomerInfoFieldModel
        set_booking_reservation_form_values={set_booking_reservation_form_values}
        booking_reservation_form_values={booking_reservation_form_values}
        i18n={props.i18n}
      />
    </>
  )
}

export default BookingReservationFormFunction;
