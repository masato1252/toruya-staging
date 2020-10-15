"use strict"

import React, { useContext } from "react";

import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { NotificationMessages } from "shared/components"
import { CustomerTopActions } from "./top_actions";

const CustomerBasicInfo = () => {
  const { dispatch, selected_customer, notification_messages } = useContext(GlobalContext)

  return (
    <div>
      <NotificationMessages notification_messages={notification_messages} dispatch={dispatch} />
      <div className="customer-basic-info">
        <CustomerTopActions
          leading={
            <i
              className="fa fa-angle-left fa-2x"
              onClick={() => {
                dispatch({
                  type: "CHANGE_VIEW",
                  payload: {
                    view: "customers_list"
                  }
                })
              }}
            >
            </i>
          }
          tail={
            <span>EDIT</span>
          }
        />
        <div className="customer-data">
          <div className="group-rank">
            <span>
              {selected_customer.groupName}
            </span>
            <span className={selected_customer.rank?.key}>
              {selected_customer.rank?.name}
            </span>
          </div>
          <div className="phonetic-name">
            <span>
              {selected_customer.phoneticLastName}
            </span>
            <span>
              {selected_customer.phoneticFirstName}
            </span>
          </div>
          <div className="name">
            <span>
              {selected_customer.lastName}
            </span>
            <span>
              {selected_customer.firstName}
            </span>
          </div>
          <div className="notifiers">
            <i className="fa fa-bell"></i>
            <i className="fa fa-phone"></i>
            <i className="fa fa-envelope"></i>
          </div>
        </div>
      </div>
    </div>
  )
}

export default CustomerBasicInfo;
