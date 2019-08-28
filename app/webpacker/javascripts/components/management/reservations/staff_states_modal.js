"use strict";

import React from "react";

class StaffStatesModal extends React.Component {
  constructor(props) {
    super(props);
  };

  _is_current_staff_approved = () => {
    const {
      staff_states,
    } = this.props.reservation_form_values;

    const {
      accepted_state,
    } = this.props.reservation_properties.reservation_staff_states

    return staff_states[this._current_staff_state_index()]["state"] === accepted_state
  }

  _current_staff_state_index = () => {
    const {
      by_staff_id,
      staff_states,
    } = this.props.reservation_form_values;

    return staff_states.findIndex((staff_state) => String(staff_state.staff_id) == String(by_staff_id))
  }

  _is_current_staff_responsible = () => {
    return this._current_staff_state_index() >= 0
  }

  handleSubmit = (event) => {
    const {
      reservation_form_values,
      reservation_properties,
      reservation_form,
    } = this.props

    const {
      pending_state,
      accepted_state,
    } = reservation_properties.reservation_staff_states

    const {
      staff_states,
    } = this.props.reservation_form_values;

    let new_staff_states = _.clone(staff_states)
    const current_staff_state_index = this._current_staff_state_index()

    if (this._is_current_staff_responsible()) {
      new_staff_states[current_staff_state_index]["state"] = this._is_current_staff_approved() ? pending_state : accepted_state

      reservation_form.change("reservation_form[staff_states]", new_staff_states)
    }

    $("#staff-states-modal").modal("hide")
  }

  render() {
    const {
      title,
      message,
      approve_btn,
      unapprove_btn,
    } = this.props.i18n.modal.staff_states

    const {
      total_staffs_number,
      accepted_staffs_number,
    } = this.props

    const {
      staff_states,
    } = this.props.reservation_form_values

    const {
      staff_options,
      reservation_staff_states: {
        pending_state,
        accepted_state,
      }
    } = this.props.reservation_properties

    let parsed_message = message.replace(/%{total_staffs_number}/, total_staffs_number)
    parsed_message = parsed_message.replace(/%{accepted_staffs_number}/, accepted_staffs_number)

    const staff_states_info = staff_states.map((staff_state) => {
      const match_staff_option =  staff_options.find((staff_option) => String(staff_option.value) === String(staff_state.staff_id))
      const state_icon = staff_state.state === accepted_state ? <i className="fa fa-calendar-check-o"></i> : <i className="fa fa-calendar"></i>

      return (
        <div key={`${staff_state.staff_id}-${staff_state.state}`}>
          {state_icon}
          <span>{match_staff_option.name}</span>
        </div>
      )
    })

    return (
      <div className="modal fade" id="staff-states-modal" tabIndex="-1" role="dialog">
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
              <h4 className="modal-title">
                {title}
              </h4>
            </div>

            <div className="modal-body">
              <div>
                {parsed_message}
              </div>
              <div>
                {staff_states_info}
              </div>
            </div>

            <div className="modal-footer centerize">
              <dl>
                <dd>
                  <button id="BTNsave" className="btn BTNyellow" onClick={this.handleSubmit} disabled={!this._is_current_staff_responsible()}>
                    {this._is_current_staff_responsible() && this._is_current_staff_approved() ? unapprove_btn : approve_btn}
                  </button>
                </dd>
              </dl>
            </div>
          </div>
        </div>
      </div>
    );
  }
};

export default StaffStatesModal;
