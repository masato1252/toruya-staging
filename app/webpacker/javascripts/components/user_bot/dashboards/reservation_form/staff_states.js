"use strict"

import React from "react";
import StaffStatesModal from "./staff_states_modal";

const StaffStates = ({staff_states, menu_staffs_list, setStaffStates, setMenuStaffsList, all_staff_ids, props})  => {
  const {
    pending_state,
    accepted_state,
  } = props.reservation_properties.reservation_staff_states

  const _accepted_staffs_number = () => {
    const {
      accepted_state,
    } = props.reservation_properties.reservation_staff_states

    return staff_states.filter(staff_state => staff_state.state === accepted_state).length
  }

  const is_reservation_accepted = () => _accepted_staffs_number() === all_staff_ids.length
  const reservation_current_staffs_state = () => is_reservation_accepted() ? accepted_state : pending_state
  const reservation_state_wording = () => is_reservation_accepted() ? props.i18n.accepted_state : props.i18n.pending_state

  return (
    <div>
      <div
        className={`reservation-state-btn btn ${reservation_current_staffs_state()}`}
        onClick={() => $("#staff-states-modal").modal("show")} >
        {reservation_state_wording()} ({_accepted_staffs_number()}/{all_staff_ids.length})
        <i className="fa fa-pencil"></i>
      </div>
      <StaffStatesModal
        staff_states={staff_states}
        menu_staffs_list={menu_staffs_list}
        setMenuStaffsList={setMenuStaffsList}
        setStaffStates={setStaffStates}
        total_staffs_number={all_staff_ids.length}
        accepted_staffs_number={_accepted_staffs_number()}
        props={props}
      />
    </div>
  )
}

export default StaffStates;
