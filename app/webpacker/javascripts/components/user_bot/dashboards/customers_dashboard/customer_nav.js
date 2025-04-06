"use strict";

import React from "react";
import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";

const CustomerNav = () => {
  const { view, dispatch, props, selected_customer } = useGlobalContext()

  const onHandleClick = (target) => {
    if (target == view) return;

    dispatch({type: "CHANGE_VIEW", payload: { view: target }})
  }

  return (
    <ul className="nav nav-tabs text-15px">
      <li className={view == "customer_reservations" ? "active" : ""}>
        <a onClick={() => onHandleClick("customer_reservations")}>
          <i className="fa fa-calendar"></i> <span>{props.i18n.tab.customer_reservations}</span>
        </a>
      </li>
      <li className={view == "customer_messages" ? "active" : ""}>
        <a onClick={() => onHandleClick("customer_messages")}>
          <i className="fa fa-comment"></i> <span>{props.i18n.tab.customer_messages}</span>
        </a>
      </li>
      <li className={view == "customer_payments" ? "active" : ""}>
        <a onClick={() => onHandleClick("customer_payments")}>
          <i className="fas fa-money-bill-wave"></i> <span>{props.i18n.tab.customer_payments}</span>
        </a>
      </li>
      <li className={view == "customer_info_view" || view == "customer_info_form" ? "active" : ""}>
        <a onClick={() => onHandleClick("customer_info_view")}>
          <i className="fa fa-address-card"></i> <span>{props.i18n.tab.customer_info}</span>
        </a>
      </li>
    </ul>
  )
}

export default CustomerNav;
