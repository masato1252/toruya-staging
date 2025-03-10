"use strict";

import React, { useState, useRef } from "react";
import moment from 'moment-timezone';
import axios from "axios";
import _ from "lodash";
import arrayMove from "array-move"

import OwnerWarning from "./owner_warning";
import DraftWarning from "./draft_warning";
import BookingHeader from "./booking_header";
import CustomerAddressView from "./customer_address_view";
import BookingDoneView from "./booking_done_view";
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
import SurveyForm from "components/shared/survey/form";
import BookingReservationButton from "./booking_reservation_button";
import BookingOptionFirstFlow from "./booking_option_first_flow";
import ProductRequirementView from "./product_requirement_view";
import 'bootstrap-sass/assets/javascripts/bootstrap/modal';
import { CommonServices } from "user_bot/api";
import { getMomentLocale } from "libraries/helper.js";

const BookingReservationFormFunction = ({props}) => {
  moment.locale(getMomentLocale(props.locale));
  let findCustomerCall;

  const [booking_reservation_form_values, set_booking_reservation_form_values] = useState(props.booking_reservation_form)
  const stripe_token_ref = useRef();
  const square_token_ref = useRef();
  const address_ref = useRef();
  const bookingReservationLoading_ref = useRef();

  const isCustomerAddressFilled = () => {
    const { customer_info } = booking_reservation_form_values

    return customer_info.address_details?.zip_code && customer_info.address_details?.region && customer_info.address_details?.city
  }

  const selected_booking_options = () => {
    const { booking_options, booking_option_ids } = booking_reservation_form_values;

    return _.filter(booking_options, (booking_option) => {
      return booking_option_ids?.includes(booking_option.id)
    })
  }

  const isOnlinePayment= () => {
    return _.some(selected_booking_options(), option => option?.is_online_payment)
  }

  const handleAddressCallback = (address) => {
    const { is_filling_address } = booking_reservation_form_values
    set_booking_reservation_form_values(prev => ({...prev, customer_info: {...prev.customer_info, address_details: address }}))
    address_ref.current = address

    if (!address) return;
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
        case "booking_option_ids":
          resetValue = []
          break;
      }

    set_booking_reservation_form_values(prev => ({...prev, [field]: resetValue}))
    })

    set_booking_reservation_form_values(prev => ({...prev, booking_option_selected_flow_done: false, is_survey_done: false, booking_failed: null, errors: {}}))
    return {};
  }

  const resetFlowValues = async () => {
    resetValues([
      "booking_option_ids",
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
        booking_option_ids: booking_reservation_form_values.booking_option_ids,
        customer_id: booking_reservation_form_values?.customer_info?.id
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
    const { booking_option_ids, booking_date, booking_at } = booking_reservation_form_values;

    return booking_option_ids && booking_date && booking_at
  }

  const isSocialLoginChecked = () => {
    const { social_user_id, customer_without_social_account, skip_social_customer } = booking_reservation_form_values

    return !props.social_account_login_required || social_user_id || customer_without_social_account || skip_social_customer
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

    if (props.support_feature_flags.support_phonetic_name) {
      return (found_customer && customer_info && customer_info.id) || (
        customer_last_name &&
        customer_first_name &&
        customer_phonetic_last_name &&
        customer_phonetic_first_name &&
        customer_phone_number
      )
    }
    else {
      return (found_customer && customer_info && customer_info.id) || (
        customer_last_name && customer_first_name && customer_phone_number
      )
    }
  }

  const isCustomerTrusted = () => {
    const { found_customer, use_default_customer, booking_code } = booking_reservation_form_values;

    return (use_default_customer && isEnoughCustomerInfo()) || (found_customer != null && booking_code && booking_code.passed)
  }

  const sorted_booking_options = (booking_options, last_selected_option_ids) => {
    const matched_index = booking_options.findIndex(option => last_selected_option_ids?.includes(option.id));

    if (matched_index > 0) {
      const targetIndex = last_selected_option_ids.indexOf(booking_options[matched_index].id);
      return arrayMove(booking_options, matched_index, targetIndex);
    }
    else {
      return booking_options
    }
  }

  const selectBookingOption = async (booking_option_id) => {
    if (props.booking_page.multiple_selection) {
      set_booking_reservation_form_values(prev => ({...prev, booking_option_ids: [...new Set([...prev.booking_option_ids, booking_option_id])]}))
    }
    else {
      set_booking_reservation_form_values(prev => ({...prev, booking_option_selected_flow_done: true, booking_option_ids: [...new Set([...prev.booking_option_ids, booking_option_id])]}))
    }
  }

  const unselectBookingOption = async (booking_option_id) => {
    set_booking_reservation_form_values(prev => ({...prev, booking_option_ids: prev.booking_option_ids.filter(id => id !== booking_option_id)}))
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

    if (props.support_feature_flags.support_phonetic_name && (!customer_phonetic_first_name || !customer_phonetic_last_name)) {
      set_booking_reservation_form_values(prev => ({...prev, errors: { ...prev.errors, customer_phonetic_name_failed_message: props.i18n.message.customer_phonetic_name_failed_message}}))
    }

    if (props.support_feature_flags.support_phonetic_name) {
      if (customer_first_name && customer_last_name && customer_phonetic_last_name && customer_phonetic_first_name) {
        set_booking_reservation_form_values(prev => ({...prev, errors: {}}))
      }
    }
    else {
      if (customer_first_name && customer_last_name && customer_phone_number) {
        set_booking_reservation_form_values(prev => ({...prev, errors: {}}))
      }
    }
  }

  const selected_booking_options_need_to_pay = () => {
    return selected_booking_options().filter(option => !props.booking_options_quota[option.id]?.ticket_code);
  }

  const selected_booking_options_need_to_pay_price = () => {
    let total_price = selected_booking_options_need_to_pay().map(option => option.price_amount).reduce((a, b) => a + b, 0)

    // price_text_sample = selected_booking_options_need_to_pay()[0].price_text
    // price_text_sample's price part is like "100,000円", might got delimiter issue
    // use total price to replace price_text_sample pricepart, and provide proper delimiter
    return props.money_sample.replace(/[\d]+/, total_price.toLocaleString())
  }

  const findCustomer = async (event) => {
    event.preventDefault();
    await validateData()
    const { customer_first_name, customer_last_name, customer_phonetic_last_name, customer_phonetic_first_name, customer_phone_number } = booking_reservation_form_values;

    if (props.support_feature_flags.support_phonetic_name) {
      if (!(customer_first_name && customer_last_name && customer_phonetic_last_name && customer_phonetic_first_name)) {
        return;
      }
    }
    else {
      if (!(customer_first_name && customer_last_name && customer_phone_number)) {
        return;
      }
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
      last_selected_option_ids,
      booking_code,
    } = response.data;

    set_booking_reservation_form_values(prev => ({
      ...prev,
      customer_info: customer_info,
      present_customer_info: customer_info,
      found_customer: Object.keys(customer_info).length ? true : false,
      last_selected_option_ids: last_selected_option_ids,
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

  const handleSubmit = async (e) => {
    if (e) e.preventDefault();
    const { is_paying_booking } = booking_reservation_form_values

    if (bookingReservationLoading_ref.current) return;

    const stripe_token = stripe_token_ref.current
    const square_token = square_token_ref.current
    if (is_paying_booking && !stripe_token && !square_token) return;

    bookingReservationLoading_ref.current = true
    let data = _.merge(
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
        "booking_option_ids",
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
        "sale_page_id",
        "survey_answers"
      ),
      {
        stripe_token,
        square_token,
        function_access_id: props.function_access_id
      }
    )

    if (address_ref.current || !data["customer_info"]["address_details"]) {
      data["customer_info"]["address_details"] = address_ref.current || {}
    }

    if (!data["customer_info"]["original_address_details"]) {
      data["customer_info"]["original_address_details"] = {}
    }

    try {
      const [_error, response] = await CommonServices.create({
        url: props.path.save,
        data: data
      })

      bookingReservationLoading_ref.current = false

      const { status, errors } = response.data;

      if (status === "successful") {
        set_booking_reservation_form_values(prev => ({...prev, is_done: true, submitting: false }))
      }
      else if (status === "failed") {
        set_booking_reservation_form_values(prev => ({...prev, booking_failed: true, submitting: false}))

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
      console.error(error)
      location.reload()
    }
  }

  const renderBookingFlow = () => {
    const { is_single_option, is_started, is_ended } = props.booking_page
    const { is_done, is_paying_booking, is_filling_address, booking_option_ids, skip_social_customer, found_customer, is_survey_done, submitting } = booking_reservation_form_values

    if (props.product_requirement) {
      return (
        <ProductRequirementView
          product_name={props.product_requirement.product_name}
          social_account_login_url={props.social_account_login_url}
          social_account_add_friend_url={props.social_account_add_friend_url}
          social_customer_exists={props.social_customer_exists}
        />
      )
    }

    if (!isOnlinePayment() && (props.booking_page.is_customer_address_required ? !isCustomerAddressFilled() : false) && (is_filling_address || is_done || is_paying_booking)) {
      return (
        <CustomerAddressView
          handleAddressCallback={handleAddressCallback}
          address={booking_reservation_form_values.customer_info.address_details}
        />
      )
    }

    if (is_done) {
      return (
        <BookingDoneView
          i18n={props.i18n}
          booking_option_ids={booking_option_ids}
          booking_date={booking_reservation_form_values.booking_date}
          social_account_add_friend_url={props.social_account_add_friend_url}
          social_account_login_url={props.social_account_login_url}
          booking_page_url={props.booking_page.url}
          tickets={booking_option_ids.map(id => props.booking_options_quota[id]).filter(Boolean)}
          selected_booking_options={selected_booking_options()}
          skip_social_customer={skip_social_customer}
          function_access_id={props.function_access_id}
        />
      )
    }

    if (is_paying_booking) {
      return (
        <div>
          <ChargingView
            booking_date={booking_reservation_form_values.booking_date}
            booking_at={booking_reservation_form_values.booking_at}
            time_from={props.i18n.time_from}
            payment_solution={props.payment_solution}
            handleTokenCallback={async (token) => {
              if (props.payment_solution.solution == "stripe_connect") {
                stripe_token_ref.current = token
              }
              else {
                square_token_ref.current = token
              }

              handleSubmit()
            }}
            product_name={selected_booking_options_need_to_pay().map(option => option.name).join("<br />")}
            booking_details={`${moment.tz(`${booking_reservation_form_values.booking_date} ${booking_reservation_form_values.booking_at}`, "YYYY-MM-DD HH:mm", props.timezone).format("llll")} ${props.i18n.time_from}`}
            product_price={selected_booking_options_need_to_pay_price()}
          />
          <BookingFailedArea
            booking_failed={booking_reservation_form_values.booking_failed}
            booking_failed_message={booking_reservation_form_values.errors?.booking_failed_message}
            booking_page_url={props.booking_page.url}
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

    return (
      <div>
        <BookingOptionFirstFlow
          set_booking_reservation_form_values={set_booking_reservation_form_values}
          booking_reservation_form_values={booking_reservation_form_values}
          booking_options_quota={props.booking_options_quota}
          i18n={props.i18n}
          sorted_booking_options={sorted_booking_options}
          selectBookingOption={selectBookingOption}
          unselectBookingOption={unselectBookingOption}
          timezone={props.timezone}
          selected_booking_options={selected_booking_options()}
          resetFlowValues={resetFlowValues}
          calendar={props.calendar}
          fetchBookingTimes={fetchBookingTimes}
          setBookingTimeAt={setBookingTimeAt}
          resetValues={resetValues}
          scrollToTarget={scrollToTarget}
        />
        {isBookingFlowEnd() && !isSocialLoginChecked() && (
          <SocialCustomerLogin
            set_booking_reservation_form_values={set_booking_reservation_form_values}
            booking_reservation_form_values={booking_reservation_form_values}
            social_account_login_url={props.social_account_login_url}
            social_account_skippable={props.social_account_skippable}
          />
        )}
        {isBookingFlowEnd() && isSocialLoginChecked() && (
          <RegularCustomersOption
            set_booking_reservation_form_values={set_booking_reservation_form_values}
            booking_reservation_form_values={booking_reservation_form_values}
            isCustomerTrusted={isCustomerTrusted()}
            i18n={props.i18n}
            findCustomer={findCustomer}
            support_phonetic_name={props.support_feature_flags.support_phonetic_name}
            locale={props.locale}
          />
        )}
        {isBookingFlowEnd() && isSocialLoginChecked() && (found_customer || isCustomerTrusted()) && props.booking_page.survey && !is_survey_done && (
          <SurveyForm
            survey={props.booking_page.survey}
            survey_answers={booking_reservation_form_values.survey_answers}
            onSubmit={(data) => {
              console.log("survey data", data)
              set_booking_reservation_form_values(prev => ({...prev, is_survey_done: true, survey_answers: data}))
            }}
            booking_reservation_form_values={booking_reservation_form_values}
            i18n={props.i18n}
          />
        )}
        {isBookingFlowEnd() && isSocialLoginChecked() && (found_customer || isCustomerTrusted()) && (!props.booking_page.survey || is_survey_done) && !submitting && (
          <CurrentCustomerInfo
            booking_reservation_form_values={booking_reservation_form_values}
            i18n={props.i18n}
            isCustomerTrusted={isCustomerTrusted()}
            not_me_callback={() => {
              set_booking_reservation_form_values(prev => ({...prev, found_customer: null, use_default_customer: false}))
            }}
          />
        )}
        {isSocialLoginChecked() && (!props.booking_page.survey || is_survey_done) && (
          <BookingReservationButton
            set_booking_reservation_form_values={set_booking_reservation_form_values}
            booking_reservation_form_values={booking_reservation_form_values}
            i18n={props.i18n}
            booking_page={props.booking_page}
            payment_solution={props.payment_solution}
            isBookingFlowEnd={isBookingFlowEnd()}
            isEnoughCustomerInfo={isEnoughCustomerInfo()}
            isCustomerTrusted={isCustomerTrusted()}
            isOnlinePayment={isOnlinePayment()}
            isCustomerAddressRequired={props.booking_page.is_customer_address_required}
            isCustomerAddressFilled={isCustomerAddressFilled()}
            handleSubmit={handleSubmit}
            is_single_option={is_single_option}
            tickets={booking_option_ids.map(id => props.booking_options_quota[id]).filter(Boolean).filter(ticket => ticket.ticket_code)}
            resetBookingFailedValues={resetBookingFailedValues}
          />
        )}
      </div>
    )
  }

  return (
    <>
      <form>
        <OwnerWarning i18n={props.i18n} is_shop_owner={props.is_shop_owner} is_done={booking_reservation_form_values.is_done} />
        <DraftWarning i18n={props.i18n} booking_page={props.booking_page} />
        <BookingHeader booking_page={props.booking_page} is_done={booking_reservation_form_values.is_done} />
        {renderBookingFlow()}
      </form>

      <CustomerInfoModal
        set_booking_reservation_form_values={set_booking_reservation_form_values}
        booking_reservation_form_values={booking_reservation_form_values}
        i18n={props.i18n}
        support_phonetic_name={props.support_feature_flags.support_phonetic_name}
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
