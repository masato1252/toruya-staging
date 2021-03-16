"use strict";

import React, { useEffect, useState } from "react";

import LineIdentificationView from "components/lines/customer_identifications/shared/line_identification_view"
import CustomerIdentificationView from "components/lines/customer_identifications/shared/identification_view"
import { SaleServices } from "user_bot/api";
import { CheckInLineBtn } from "shared/booking";
import I18n from 'i18n-js/index.js.erb';

const FinalPaidPage = ({props, purcahse_data}) => {
  useEffect(() => {
    SaleServices.purchase({ data: purcahse_data })
  }, [])

  return (
    <div className="done-view">
      <h3 className="title">
        {I18n.t('common.thanks')}
      </h3>

      <CheckInLineBtn social_account_add_friend_url={props.add_friend_url}>
        <div className="message break-line-content">
          {I18n.t("online_service_purchases.service_content")}
          <br />
          <div dangerouslySetInnerHTML={{ __html: I18n.t("online_service_purchases.please_check_in_line")  }} />
        </div>
      </CheckInLineBtn>
    </div>
  )
}

export const CustomerPurchases = ({props}) => {
  const { social_user_id, customer_id } = props.social_customer;
  const [identified_customer, setIdentifiedCustomer] = useState(customer_id)

  if (!social_user_id) {
    return <LineIdentificationView line_login_url={props.line_login_url} />
  }

  if (identified_customer) {
    return (
      <FinalPaidPage
        props={props}
        purcahse_data={
          {
            slug: props.sale_page_slug,
            customer_id: identified_customer
          }
        }
      />
    )
  }

  return (
    <CustomerIdentificationView
      social_user_id={social_user_id}
      customer_id={customer_id}
      i18n={props.i18n}
      identifiedCallback={
        (customer) => {
          setIdentifiedCustomer(customer.customer_id)
        }
      }
    />
  )
}

export default CustomerPurchases;
