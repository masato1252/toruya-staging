"use strict";

import React from "react";

const CustomerElement = ({customer, selected, onHandleClick, stateIcon}) => {
  return (
    <div
      key={customer.id}
      className={`customer-option ${selected ? "here" : ""} ${customer.state === "canceled" ? "canceled" : ""}`}
      onClick={onHandleClick}
    >
      <div className="customer-symbol">
        {stateIcon}
        <span className={`customer-level-symbol ${customer.rank && customer.rank.key}`}>
          <i className="fa fa-address-card"></i>
        </span>
        <i className={`customer-reminder-permission fa fa-bell ${customer.reminderPermission ? "reminder-on" : ""}`}></i>
        {customer.socialUserId  &&  <i className="fa fab fa-line"></i>}
      </div>

      <div className="customer-info">
        <p>{customer.label}</p>
        <p className="place">
          {customer.addressDetails?.region}
          {customer.addressDetails?.city}
        </p>
      </div>
    </div>
  )
}

export default CustomerElement;
