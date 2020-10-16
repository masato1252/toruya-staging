"use strict"

import React, { useContext } from "react";

import { GlobalContext } from "context/user_bots/reservation_form/global_state";

const CustomerModal = () => {
  const { selected_customer, dispatch, props } = useContext(GlobalContext)

  const {
    is_editable,
    current_staff_name,
    reservation_staff_states: {
      pending_state,
      accepted_state,
    }
  } = props.reservation_properties

  return (
    <div className="modal fade" id="customer-modal" tabIndex="-1" role="dialog">
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
          </div>
          <div className="modal-body">
            {selected_customer?.id}
          </div>
        </div>
      </div>
    </div>
  )
}

export default CustomerModal
