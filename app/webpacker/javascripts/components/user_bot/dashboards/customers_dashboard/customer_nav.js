"use strict";

import React, { useContext } from "react";
import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";

const CustomerNav = () => {
  const { view, dispatch } = useContext(GlobalContext)

  const onHandleClick = (target) => {
    if (target == view) return;

    dispatch({type: "CHANGE_VIEW", payload: { view: target }})
  }

  return (
    <ul className="nav nav-tabs">
      <li className={view == "customer_reservations" ? "active" : ""}>
        <a onClick={() => onHandleClick("customer_reservations")}>reservations</a>
      </li>
      <li className={view == "customer_messages" ? "active" : ""}>
        <a onClick={() => onHandleClick("customer_messages")}>Line</a>
      </li>
      <li className={view == "customer_info_view" || view == "customer_info_edit" ? "active" : ""}>
        <a onClick={() => onHandleClick("customer_info_view")}>Info</a>
      </li>
    </ul>
  )
}

export default CustomerNav;
