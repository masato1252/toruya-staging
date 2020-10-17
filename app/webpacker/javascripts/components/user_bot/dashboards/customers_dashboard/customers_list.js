"use strict";

import React, { useContext, useEffect } from "react";
import Popup from "reactjs-popup";
import InfiniteScroll from 'react-infinite-scroll-component';

import { GlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { TopNavigationBar, BottomNavigationBar, NotificationMessages } from "shared/components"
import CustomerSearchBar from "./customer_search_bar"
import CustomerElement from "./customer_element"

const BottomBar = () => {
  const { customers } = useContext(GlobalContext)

  return (
    <BottomNavigationBar klassName="center">
      <span>{customers.length}</span>
    </BottomNavigationBar>
  )
}

const CustomerFilterCharacter = () =>{
  const { filter_pattern_number, filterCustomers } = useContext(GlobalContext)
  const characters = ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "A"]

  return (
    <div className="filter-character-action">
      <Popup
        trigger={<span className="current-filter-character">{characters[filter_pattern_number || 0]}</span>}
        position="bottom"
        on="click"
        closeOnDocumentClick
        mouseLeaveDelay={300}
        mouseEnterDelay={0}
        contentStyle={{ padding: '0px', border: 'none' }}
        arrow={false}
      >
        {close => (
          <div className="filter-character-list">
            {
              characters.map((symbol, i) => {
                return (
                  <div key={symbol} onClick={() => {
                    filterCustomers(i)
                    close()
                  }}  className="filter-character-element" >
                    {symbol}
                  </div>
                )
              })
            }
          </div>
        )}
      </Popup>
    </div>
  )
}

const TopBar = () => {
  return (
    <TopNavigationBar
      leading={<i className="fa fa-angle-left fa-2x"></i>}
      title={"title"}
      action={<CustomerFilterCharacter />}
    />
  )
}
const UserBotCustomersList = ({}) => {
  const { customers, selected_customer, is_all_customers_loaded, getCustomers, dispatch, notification_messages } = useContext(GlobalContext)

  useEffect(() => {
    getCustomers()
  }, [])

  return (
    <div className="customers-dashboard">
      <div className="customers-list-dashboard">
        <TopBar />
        <CustomerSearchBar />
        <NotificationMessages notification_messages={notification_messages} dispatch={dispatch} />
        <InfiniteScroll
          className="customers-list"
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
            return <CustomerElement
              key={`customer-element-${customer.id}`}
              customer={customer}
              selected={selected_customer?.id == customer.value}
              onHandleClick={() => {
                dispatch({
                  type: "SELECT_CUSTOMER",
                  payload: { customer }
                })

                dispatch({
                  type: "CHANGE_VIEW",
                  payload: { view: "customer_info_view" }
                })
              }}
            />
          })}
        </InfiniteScroll>
        <BottomBar />
      </div>
    </div>
  )
}

export default UserBotCustomersList;
