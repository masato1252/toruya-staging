"use strict";

import React, { useContext } from "react";

import { GlobalContext } from "context/user_bots/reservation_form/global_state";

const StaffStatesModal = ({total_staffs_number, accepted_staffs_number}) => {
  const { staff_states, props, all_staff_ids, dispatch } = useContext(GlobalContext)

  const {
    title,
    message,
    approve_btn,
    unapprove_btn,
  } = props.i18n.modal.staff_states

  const {
    staff_options,
    reservation_staff_states: {
      pending_state,
      accepted_state,
    }
  } = props.reservation_properties

  const _is_current_staff_approved = () => {
    const { accepted_state } = props.reservation_properties.reservation_staff_states

    return staff_states[_current_staff_state_index()]["state"] === accepted_state
  }

  const _current_staff_state_index = () => {
    const { by_staff_id } = props.reservation_form;

    return staff_states.findIndex((staff_state) => String(staff_state.staff_id) == String(by_staff_id))
  }

  const _is_current_staff_responsible = () => {
    return _current_staff_state_index() >= 0
  }

  const handleSubmit = (event) => {
    const {
      pending_state,
      accepted_state,
    } = props.reservation_properties.reservation_staff_states

    let new_staff_states = _.clone(staff_states)
    const current_staff_state_index = _current_staff_state_index()

    if (_is_current_staff_responsible()) {
      new_staff_states[current_staff_state_index]["state"] = _is_current_staff_approved() ? pending_state : accepted_state

      dispatch({
        type: "UPDATE_STAFF_STATES",
        payload: new_staff_states
      })
    }

    $("#staff-states-modal").modal("hide")
  }

  const parsed_message = () => {
    let parsed_message = message.replace(/%{total_staffs_number}/, total_staffs_number)
    return parsed_message.replace(/%{accepted_staffs_number}/, accepted_staffs_number)
  }

  const staff_states_info = () => {
    return staff_states.map((staff_state) => {
      const match_staff_option =  staff_options.find((staff_option) => String(staff_option.value) === String(staff_state.staff_id))
      const state_icon = staff_state.state === accepted_state ? <i className="fa fa-calendar-check"></i> : <i className="fa fa-calendar"></i>

      return (
        <div key={`${staff_state.staff_id}-${staff_state.state}`}>
          {state_icon}
          <span>{match_staff_option?.name}</span>
        </div>
      )
    })
  }

  return (
    <div className="modal fade" id="staff-states-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
            <h4 className="modal-title">
            </h4>
          </div>

          <div className="modal-body">
            <div>
              {parsed_message()}
            </div>
            <div>
              {staff_states_info()}
            </div>
          </div>

          <div className="modal-footer centerize">
            <dl>
              <dd>
                <button id="BTNsave" className="btn enhanced BTNyellow" onClick={handleSubmit} disabled={!_is_current_staff_responsible()}>
                  {_is_current_staff_responsible() && _is_current_staff_approved() ? unapprove_btn : approve_btn}
                </button>
              </dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StaffStatesModal;
