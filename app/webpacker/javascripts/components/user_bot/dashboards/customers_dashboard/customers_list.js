"use strict";

import React, { useEffect } from "react";
import Popup from "reactjs-popup";
import InfiniteScroll from 'react-infinite-scroll-component';
import { useHistory } from "react-router-dom";

import { useGlobalContext } from "context/user_bots/customers_dashboard/global_state";
import { TopNavigationBar, BottomNavigationBar, NotificationMessages, ChangeLogsNotifications } from "shared/components"
import CustomerSearchBar from "./customer_search_bar"
import CustomerElement from "./customer_element"

const BottomBar = () => {
  const { customers, dispatch, props, total_customers_number } = useGlobalContext()
  let history = useHistory();

  return (
    <BottomNavigationBar klassName="centerize">
      <span>{props.i18n.count}{total_customers_number}{props.i18n.unit}</span>
      <button
        className="btn btn-yellow btn-circle btn-save btn-tweak btn-big btn-extend-right"
        onClick={() => {
          dispatch({type: "CHANGE_VIEW", payload: { view: "customer_info_form" }})
          dispatch({type: "SELECT_CUSTOMER", payload: { customer: { contactGroupId: props.contact_groups[0]?.value } } })
          history.push(Routes.lines_user_bot_customers_path({business_owner_id: props?.shop?.user_id}));
        }
        } >
        <i className="fa fa-plus fa-2x"></i>
      </button>
    </BottomNavigationBar>
  )
}

const CustomerFilterCharacter = () =>{
  const { filter_pattern_number, filterCustomers, props } = useGlobalContext()

  if (!props.support_feature_flags.support_character_filter) {
    return <i className="fa fa-filter"></i>
  }

  return (
    <div className="filter-character-action">
      <Popup
        trigger={<span className="current-filter-character">{CustomerFilterCharacter.characters[filter_pattern_number || 0]}</span>}
        position="bottom"
        on="click"
        closeOnDocumentClick
        mouseLeaveDelay={300}
        mouseEnterDelay={0}
        contentStyle={{ padding: '0px', border: 'none', width: '40px' }}
        arrow={false}
      >
        {close => (
          <div className="filter-character-list">
            {
              CustomerFilterCharacter.characters.map((symbol, i) => {
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

CustomerFilterCharacter.characters = ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "A"]

const TopBar = () => {
  const { props } = useGlobalContext()
  let leading;

  return (
    <TopNavigationBar
      leading={props.from == "reservation" ? <a href={props.referrer}><i className="fa fa-angle-left fa-2x" ></i></a> : <i></i>}
      title={props.i18n.title}
      action={<CustomerFilterCharacter />}
    />
  )
}
const UserBotCustomersList = ({}) => {
  const { view, customers, selected_customer, is_all_customers_loaded, getCustomers, dispatch, notification_messages, props, selectCustomer } = useGlobalContext()
  let history = useHistory();

  useEffect(() => {
    getCustomers()
  }, [])

  if (view !== "customers_list") {
    return <></>
  }

  return (
    <div className="customers-dashboard">
      <div className="customers-list-dashboard">
        <TopBar />
        <CustomerSearchBar />
        <NotificationMessages notification_messages={notification_messages} dispatch={dispatch} />
        <ChangeLogsNotifications />
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
              <strong className="no-more-customer">{props.i18n.no_more_customer}</strong>
            </p>
          }
        >
          {customers.map((customer) => {
            return <CustomerElement
              key={`customer-element-${customer.id}`}
              customer={customer}
              selected={selected_customer?.id == customer.value}
              onHandleClick={() => {
                selectCustomer(customer)
                history.push(Routes.lines_user_bot_customers_path({customer_id: customer.id, business_owner_id: props.business_owner_id}));
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
