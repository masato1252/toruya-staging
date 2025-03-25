"use strict"

import React, { useEffect, useState, useContext, useCallback } from "react";
import { useForm } from "react-hook-form";
import arrayMove from "array-move";
import moment from "moment-timezone";
import _ from "lodash";
import Popup from 'reactjs-popup';

import { ReservationServices } from "user_bot/api";
import ProcessingBar from "shared/processing_bar.js"
import { TopNavigationBar, BottomNavigationBar } from "shared/components"
import CalendarModal from "./calendar_modal";
import ScheduleModal from "./schedule_modal";
import CustomerModal from "./customer_modal";
import MenuStaffsList from "./menu_staffs_list";
import ReservationCustomersList from "./customers_list";
import StaffStates from "./staff_states";
import { displayErrors, zeroPad, getMomentLocale } from "libraries/helper.js"

import { GlobalProvider, GlobalContext } from "context/user_bots/reservation_form/global_state"

const Form = () => {
  const [initial, setInitial] = useState(true)
  const {
    reservation_errors, menu_staffs_list, staff_states, customers_list, props, dispatch, all_staff_ids, all_menu_ids,
    processing, setProcessing,
    register, handleSubmit, watch, setValue, clearErrors, setError, errors, formState, getValues, control,
    start_time_date_part, start_time_time_part, start_at, end_at
  } = useContext(GlobalContext)

  const { i18n } = props

  // Use the reusable utility function to get moment locale
  const appLocale = props.locale || "tw";
  moment.locale(getMomentLocale(appLocale));

  useEffect(() => {
    if (props.book_next_time) {
      $("#calendar-modal").modal("show");
    }
  }, [])

  const onSelectStartDate = (date) => {
    setValue("start_time_date_part", date)

    $("#calendar-modal").modal("hide");
    // Only first time onSelectStartDate don't schedule modal
    if (!initial) {
      $("#schedule-modal").modal("show");
    }
    setInitial(false)
  }

  const onConfirmSelectStartDate = (date) => {
    $("#schedule-modal").modal("hide");
  }

  useEffect(() => {
    const { by_staff_id } = props.reservation_form;
    const {
      existing_staff_states,
      reservation_staff_states: {
        pending_state,
        accepted_state,
      }
    } = props.reservation_properties;

    const new_staff_states = all_staff_ids().map((staff_id) => {
      let state;
      let existing_staff_state = staff_states.find(staff_state => String(staff_state.staff_id) === String(staff_id))
      existing_staff_state = existing_staff_state || existing_staff_states.find(staff_state => String(staff_state.staff_id) === String(staff_id))

      if (existing_staff_state) {
        state = existing_staff_state.state
      }
      else if (String(staff_id) === String(by_staff_id)) {
        state = accepted_state
      }
      else {
        state = pending_state
      }

      return (
        {
          staff_id: staff_id,
          state: state
        }
      )
    })

    dispatch({
      type: "UPDATE_STAFF_STATES",
      payload: new_staff_states
    })
  }, [menu_staffs_list])

  useEffect(() => {
    debounceValidateReservation()
  }, [start_time_date_part, start_time_time_part, menu_staffs_list])

  const validateReservation = async () => {
    if (!start_time_date_part) return;

    setProcessing(true)
    const params = _.merge(
      getValues(),
      {
        end_time_date_part: start_time_date_part,
        end_time_time_part: end_at()?.format("HH:mm"),
        reservation_id: props.reservation_form.reservation_id,
        menu_staffs_list,
        staff_states
      }
    )

    const [error, response] = await ReservationServices.validate({ business_owner_id: props.business_owner_id, shop_id: props.reservation_form.shop.id, reservation_id: props.reservation_form.reservation_id, data: params })

    if (response?.data) {
      dispatch({
        type: "UPDATE_RESERVATION_ERRORS",
        payload: response.data
      })
    }

    setProcessing(false)
  }
  const debounceValidateReservation = useCallback(_.debounce(validateReservation, 500, true), [])

  const _isValidToReserve = () => {
    return (
      menu_staffs_list.length &&
      all_menu_ids().length &&
      all_staff_ids().length
    )
  }

  const onSubmit = async (data) => {
    if (!_isValidToReserve()) return;

    let error, response;

    setProcessing(true)
    const params = _.merge(
      data,
      {
        end_time_date_part: data.start_time_date_part,
        end_time_time_part: end_at().format("HH:mm"),
        by_staff_id: props.reservation_form.by_staff_id,
        menu_staffs_list,
        staff_states,
        customers_list,
        from: props.params.from,
        customer_id: props.params.customer_id
      }
    )

    if (props.reservation_form.reservation_id) {
      if (props.book_next_time) {
        [error, response] = await ReservationServices.create({ business_owner_id: props.business_owner_id, shop_id: props.reservation_form.shop.id, data: params })
      }
      else {
        [error, response] = await ReservationServices.update({ business_owner_id: props.business_owner_id, shop_id: props.reservation_form.shop.id, reservation_id: props.reservation_form.reservation_id, data: params })
      }
    }
    else {
      [error, response] = await ReservationServices.create({ business_owner_id: props.business_owner_id, shop_id: props.reservation_form.shop.id, data: params })
    }

    if (response?.data?.redirect_to) {
      window.location = response.data.redirect_to
    }
    setProcessing(false)
  }

  const startTimeError = () => {
    return displayErrors(reservation_errors, ["reservation_form.start_time.invalid_time"]);
  };

  const endTimeError = () => {
    return displayErrors(reservation_errors, ["reservation_form.end_time.invalid_time"]);
  };

  const dateErrors = () => {
    return displayErrors(reservation_errors, ["reservation_form.date.shop_closed"]);
  };

  const previousReservationOverlap = () => {
    return displayErrors(reservation_errors, ["reservation_form.start_time.interval_too_short"]).length != 0;
  };

  const nextReservationOverlap = () => {
    return displayErrors(reservation_errors, ["reservation_form.end_time.interval_too_short"]).length != 0;
  };

  const displayIntervalOverlap = () => {
    return displayErrors(reservation_errors, ["reservation_form.start_time.interval_too_short"]) &&
      displayErrors(reservation_errors, ["reservation_form.end_time.interval_too_short"])
  }

  return (
    <div className="reservation-form form">
      <ProcessingBar processing={processing} />
      <TopNavigationBar
        leading={<a href={props.from}><i className="fa fa-angle-left fa-2x"></i></a>}
        title={props.reservation_form.reservation_id ? `${i18n.edit_reservation} - ${props.reservation_form.shop.short_name}` : `${i18n.new_reservation} - ${props.reservation_form.shop.short_name}`}
      />
      <div className="form-body">
        <div className="field-header">{i18n.reservation_time}</div>
        <div className="field-row"
          onClick={() => {
            $("#calendar-modal").modal("show");
          }} >
          <input ref={register({ required: true })} name="start_time_date_part" type="hidden" />
          <span>{i18n.date}</span>
          <span>
            {moment(start_time_date_part).format("YYYY/MM/DD(dd)")} <i className="fa fa-pencil-alt"></i>
            <span className="errors">
              {dateErrors()}
            </span>
          </span>
        </div>
        <div className="field-row" >
          <span>{i18n.start_time}</span>
          <span>
            <input
              ref={register({ required: true })}
              name="start_time_time_part"
              placeholder="start_time_time_part"
              type="time"
              className={`start-time-input ${previousReservationOverlap() ? "field-warning" : ""}`}
            />
          </span>
          {startTimeError()}
        </div>
        <div className="field-row" >
          <span>{i18n.end_time}</span>
          <span>
            {end_at() ? end_at().locale('en').format("HH:mm") : i18n.no_ending_time_message}
          </span>
          {displayIntervalOverlap()}
          {endTimeError()}
        </div>

        <div className="field-row" >
          <span>{i18n.staff_states_title}</span>
          <span>
            <StaffStates />
          </span>
        </div>
        <div className="field-header">{i18n.reservation_content}</div>
        <MenuStaffsList
          useDragHandle
          onSortEnd = {({oldIndex, newIndex}) => {
            dispatch({
              type: "UPDATE_MENU_STAFFS_LIST",
              payload: arrayMove([...menu_staffs_list], oldIndex, newIndex)
            })
          }}
        />
        {/* Only any menu is online, show the meeting url */}
        {_.some(menu_staffs_list, ['menu_online', true]) && (
          <>
            <div className="field-header">{i18n.meeting_url}</div>
            <div className="py-2">
              <input ref={register} name="meeting_url" type="text" placeholder={i18n.meeting_url} className="extend" />
            </div>
          </>
        )}

        <ReservationCustomersList />
        <div className="field-header">{i18n.memo}</div>
        <textarea
          ref={register}
          name="memo"
          placeholder={i18n.memo}
        />
      </div>
      <BottomNavigationBar klassName="centerize">
        <>
          {props.reservation_form.reservation_id && (
            <a className="btn btn-orange btn-circle btn-delete"
              data-confirm={i18n.delete_confirmation_message}
              rel="nofollow"
              data-method="delete"
              href={Routes.lines_user_bot_shop_reservation_path(props.business_owner_id, props.reservation_form.shop.id, props.reservation_form.reservation_id, { from_customer_id: props.reservation_form.from_customer_id || "" })}>
              <i className="fa fa-trash fa-2x" aria-hidden="true"></i>
            </a>
)}
          <span>
            {props.reservation_form.reservation_id ? zeroPad(props.reservation_form.reservation_id, 7) : ""}
          </span>
          <button

            disabled={!_isValidToReserve() || processing}
            onClick={handleSubmit(onSubmit)}
            className="btn btn-yellow btn-circle btn-save btn-extend-right btn-with-word"
          >
            <i className="fa fa-save fa-2x"></i>
            <div className="word">{i18n.save}</div>
          </button>
        </>
      </BottomNavigationBar>
      <CalendarModal
        props={props}
        calendar={props.calendar}
        dateSelectedCallback={onSelectStartDate}
        selectedDate={start_time_date_part}
        i18n={i18n}
      />
      <ScheduleModal
        props={props}
        selectedDate={start_time_date_part}
        i18n={i18n}
      />
      <CustomerModal />
    </div>
  )
}

const UserBotReservationForm = ({props}) => {
  return (
    <GlobalProvider props={props}>
      <Form />
    </GlobalProvider>
  )
}

export default UserBotReservationForm
