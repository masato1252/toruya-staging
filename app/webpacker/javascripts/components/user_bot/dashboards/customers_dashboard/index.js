"use strict"

import React, { useState, useContext, useEffect } from "react";
import UserBotCustomersList from "./customers_list"
import UserBotCustomerInfoView from "./customer_info_view"
import UserBotCustomerInfoForm from "./customer_info_form"
import UserBotCustomerReservations from "./customer_reservations"
import UserBotCustomerMessages from "./customer_messages"
import UserBotCustomerPayments from "./customer_payments"
import { BrowserRouter as Router } from "react-router-dom";
import { GlobalProvider, GlobalContext } from "context/user_bots/customers_dashboard/global_state"
import { compatRead } from "../../../../libraries/compat_api";

const DashboardView = () => {
  const { view, props, dispatch, customers } = useContext(GlobalContext)

  useEffect(() => {
    if (props.customer?.id) {
      dispatch({
        type: "SELECT_CUSTOMER",
        payload: {
          customer: props.customer
        }
      })

      dispatch({
        type: "CHANGE_VIEW",
        payload: {
          view: props.target_view || "customer_info_view"
        }
      })
    }
  }, [])

  switch (view) {
    case "customer_info_view":
      return <UserBotCustomerInfoView />
    case "customer_reservations":
      return <UserBotCustomerReservations />
    case "customer_info_form":
      return <UserBotCustomerInfoForm />
    case "customer_messages":
      return <UserBotCustomerMessages />
    case "customer_payments":
      return <UserBotCustomerPayments />
    default:
      return <></>
  }
}

const UserBotCustomersDashboard = ({props}) => {
  const [readyProps, setReadyProps] = useState(props.compat_read_enabled ? null : props);
  const [loadError, setLoadError] = useState(false);

  useEffect(() => {
    if (!props.compat_read_enabled) return;

    let cancelled = false;
    const query = props.current_user_id ? `?current_user_id=${props.current_user_id}` : "";
    compatRead(`/lines/user_bot/owner/${props.business_owner_id}/customers/page_context${query}`)
      .then((body) => {
        if (cancelled) return;
        const ctx = body.data || {};
        setReadyProps({
          ...props,
          total_customers_number: ctx.total_customers_number,
          contact_groups: ctx.contact_groups || [],
          ranks: ctx.ranks || [],
          customer_tags: ctx.customer_tags || props.customer_tags || [],
          block_toruya_message_reply: ctx.block_toruya_message_reply ?? props.block_toruya_message_reply,
          is_customer_notification_channel_line: ctx.customer_notification_channel === "line",
          over_free_limit: ctx.over_free_limit,
        });
        if (ctx.over_free_limit && props.over_free_limit_path) {
          window.location.href = props.over_free_limit_path;
        }
      })
      .catch(() => {
        if (!cancelled) setLoadError(true);
      });

    return () => {
      cancelled = true;
    };
  }, [props.compat_read_enabled, props.business_owner_id, props.current_user_id]);

  if (loadError) {
    return (
      <div className="centerize">
        <p className="danger">顧客情報を読み込めませんでした。</p>
        <button className="btn btn-tarco" onClick={() => window.location.reload()}>再読み込み</button>
      </div>
    );
  }
  if (!readyProps) return <p>Loading...</p>;

  return (
    <GlobalProvider props={readyProps}>
      <Router>
        <DashboardView />
        <UserBotCustomersList />
      </Router>
    </GlobalProvider>
  )
}

export default UserBotCustomersDashboard;
