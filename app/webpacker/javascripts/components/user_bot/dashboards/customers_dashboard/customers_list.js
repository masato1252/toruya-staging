"use strict";

import React, { useContext, useEffect } from "react";
import InfiniteScroll from 'react-infinite-scroll-component';
import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";

const UserBotCustomersList = ({}) => {
  const { customers, selected_customer, is_all_customers_loaded, getCustomers, dispatch } = useContext(GlobalContext)

  useEffect(() => {
    getCustomers()
  }, [])

  return (
    <InfiniteScroll
      dataLength={customers.length} //This is important field to render the next data
      next={getCustomers}
      hasMore={!is_all_customers_loaded}
      loader={
        <h4 className="centerize">
          <i className="fa fa-spinner fa-spin fa-fw fa-2x" aria-hidden="true"></i>
        </h4>
      }
      endMessage={
        <p>
          <strong className="no-more-customer">該当データ終了</strong>
        </p>
      }
  >
    {customers.map((customer) => {
      return (
        <div
          key={customer.id}
          className={`customer-option ${selected_customer?.id == customer.value ? "here" : ""}`}
          onClick={() => {
            dispatch({
              type: "SELECT_CUSTOMER",
              payload: { customer }
            })
          }}
        >
          <div className="customer-symbol">
            <span className={`customer-level-symbol ${customer.rank && customer.rank.key}`}>
              <i className="fa fa-address-card"></i>
            </span>
            <i className={`customer-reminder-permission fa fa-bell ${customer.reminderPermission ? "reminder-on" : ""}`}></i>
            {customer.socialUserId  &&  <i className="fa fab fa-line"></i>}
          </div>

          <div className="customer-info">
            <p>{customer.label}</p>
            <p className="place">{customer.address}</p>
          </div>
        </div>
      )
    })}
  </InfiniteScroll>
  )
}

export default UserBotCustomersList;
