"use strict"

import React, { useEffect, useState } from "react";
import { useForm, useFieldArray, useWatch } from "react-hook-form";
import arrayMove from "array-move";
import moment from "moment-timezone";
import _ from "lodash";

import { ReservationServices } from "user_bot/api";
import useCustomCompareEffect from "libraries/use_custom_compare_effect";
import ProcessingBar from "shared/processing_bar.js"
import CalendarModal from "./calendar_modal";
import MenuStaffsList from "./menu_staffs_list";
import StaffStates from "./staff_states";
import { displayErrors } from "libraries/helper.js"

const UserBotReservationForm = ({props}) => {
  moment.locale('ja');

  // TODO: disable, view tip, helper, review old form
  const i18n = props.i18n
  const [menu_staffs_list, setMenuStaffsList] = useState(props.reservation_form.menu_staffs_list)
  const [staff_states, setStaffStates] = useState(props.reservation_form.staff_states)
  const [processing, setProcessing] = useState(false)
  const [reservation_errors, setReservationErrors] = useState({})
  const { register, handleSubmit, watch, setValue, clearErrors, setError, errors, formState, getValues, control } = useForm({
    defaultValues: {
      start_time_date_part: props.reservation_form.start_time_date_part,
      start_time_time_part: props.reservation_form.start_time_time_part,
      end_time_date_part: props.reservation_form.end_time_date_part,
      end_time_time_part: props.reservation_form.end_time_time_part
    }
  });
  const start_time_date_part = watch("start_time_date_part")
  const start_time_time_part = watch("start_time_time_part")

  const start_at = () => {
    if (!start_time_date_part || !start_time_time_part) {
      return;
    }

    return moment.tz(`${start_time_date_part} ${start_time_time_part}`, "YYYY-MM-DD HH:mm", props.timezone)
  }

  const end_at = () => {
    if (!start_at() || !_.filter(menu_staffs_list, (menu_fields) => !!menu_fields.menu?.value).length) {
      return;
    }

    const total_required_time = menu_staffs_list.reduce((sum, menu_fields) => sum + Number(menu_fields.menu?.required_time || 0), 0)

    return start_at().add(total_required_time, "minutes")
  }

  const _all_staff_ids = () => {
    return _.uniq(
      _.compact(
        _.flatMap(
          menu_staffs_list, (menu_mapping) => menu_mapping.staff_ids
        ).map((staff_element) => staff_element.staff_id)
      )
    )
  }

  const onSelectStartDate = (date) => {
    setValue("start_time_date_part", date)

    $("#calendar-modal").modal("hide");
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

    const new_staff_states = _all_staff_ids().map((staff_id) => {
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

    setStaffStates(new_staff_states)
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

    const [error, response] = await ReservationServices.validate(props.reservation_form.shop.id, props.reservation_form.reservation_id, params)

    if (response?.data) {
      setReservationErrors(response.data)
    }

    setProcessing(false)
  }
  const debounceValidateReservation = _.debounce(validateReservation, 500, true)

  const _all_menu_ids = () => {
    return _.uniq(
      _.compact(
        _.flatMap(menu_staffs_list, (menu_mapping) => menu_mapping.menu_id)
      )
    )
  }

  const _isValidToReserve = () => {
    return (
      menu_staffs_list.length &&
      _all_menu_ids().length &&
      _all_staff_ids().length
    )
  }

  const onSubmit = async (data) => {
    if (!_isValidToReserve()) return;

    let error, response;

    const params = _.merge(
      data,
      {
        end_time_date_part: data.start_time_date_part,
        end_time_time_part: end_at().format("HH:mm"),
        by_staff_id: props.reservation_form.by_staff_id,
        menu_staffs_list,
        staff_states
      }
    )

    if (props.reservation_form.reservation_id) {
      [error, response] = await ReservationServices.update(props.reservation_form.shop.id, props.reservation_form.reservation_id, params)
    }
    else {
      [error, response] = await ReservationServices.create(props.reservation_form.shop.id, params)
    }

    if (response?.data?.redirect_to) {
      window.location = response.data.redirect_to
    }
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
    <div className="reservation-form">
      <ProcessingBar processing={processing}  />
      <div className="top-prev-page-bar">
        <a href={props.from}><i className="fa fa-angle-left fa-2x"></i></a>
        <span>{props.reservation_form.reservation_id ? i18n.edit_reservation : i18n.new_reservation}</span>
        <i></i>
      </div>
      <div className="form-body">
        <div className="field-header">{i18n.reservation_time}</div>
        <div className="field-row"
          onClick={() => {
            $("#calendar-modal").modal("show");
          }} >
          <input ref={register({ required: true })} name="start_time_date_part" type="hidden" />
          <span>{i18n.date}</span>
          <span>
            {moment(start_time_date_part).format("YYYY/MM/DD(dd)")}
            {reservation_errors.start_time_restriction && reservation_errors.end_time_restriction ? (
              <div className="business-hours">{reservation_errors.start_time_restriction}〜{reservation_errors.end_time_restriction}</div>
            ) : (
              <div className="business-hours closed">CLOSED</div>
            )}
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
          <span>staff states</span>
          <span>
            <StaffStates
              menu_staffs_list={menu_staffs_list}
              setMenuStaffsList={setMenuStaffsList}
              staff_states={staff_states}
              setStaffStates={setStaffStates}
              all_staff_ids={_all_staff_ids()}
              props={props}
            />
          </span>
        </div>
        <div className="field-header">{i18n.reservation_content}</div>
        <MenuStaffsList
          props={props}
          staff_states={staff_states}
          setStaffStates={setStaffStates}
          menu_staffs_list={menu_staffs_list}
          setMenuStaffsList={setMenuStaffsList}
          reservation_errors={reservation_errors}
          all_staff_ids={_all_staff_ids()}
          useDragHandle
          onSortEnd = {({oldIndex, newIndex}) => {
            setMenuStaffsList(arrayMove([...menu_staffs_list], oldIndex, newIndex) )
          }}
        />
        <div className="field-header">{i18n.memo}</div>
        <textarea
          ref={register}
          name="memo"
          placeholder={i18n.memo}
        />
      </div>
      <div className="bottom-save-bar">
        <div className="actions">
          {props.reservation_form.reservation_id && (
            <a className="btn btn-orange btn-circle btn-delete"
              data-confirm={i18n.delete_confirmation_message}
              rel="nofollow"
              data-method="delete"
              href={Routes.lines_user_bot_shop_reservation_path(props.reservation_form.shop.id, props.reservation_form.reservation_id, { from_customer_id: props.reservation_form.from_customer_id || "" })}>
              <i className="fa fa-trash fa-2x" aria-hidden="true"></i>
            </a>
          )}
          <button

            disabled={!_isValidToReserve() || processing}
            onClick={handleSubmit(onSubmit)}
            className="btn btn-yellow btn-circle btn-save"
          >
            <i className="fa fa-save fa-2x"></i>
          </button>
        </div>
      </div>
      <CalendarModal
        calendar={props.calendar}
        dateSelectedCallback={onSelectStartDate}
        selectedDate={start_time_date_part}
      />
    </div>
  )
}

export default UserBotReservationForm
