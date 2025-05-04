"use strict";

import React, { useLayoutEffect, useState } from "react";

import AddressView from "shared/address_view";
import LineIdentificationView from "components/lines/customer_identifications/shared/line_identification_view"
import CustomerIdentification from "components/lines/customer_identifications"
import { SaleServices, CommonServices } from "user_bot/api";
import CompanyHeader from "shared/company_header";
import { CheckInLineBtn } from "shared/booking";
import ServiceCheckoutForm from "shared/service_checkout_form";
import I18n from 'i18n-js/index.js.erb';

const FinalPaidPage = ({props, purchase_data}) => {
  const purchase = async () => {
    if (props.sale_page.is_free || props.customer_subscribed || props.sale_page.is_external) {
      const [error, response] = await SaleServices.purchase({ data: { ...purchase_data, payment_type: props.sale_page.payment_type, function_access_id: props.function_access_id}})

      if (error) {
        toastr.error(error.response.data.error_message)
      }

      if (props.sale_page.is_external) {
        window.location.replace(response.data.redirect_to)
      }
    }
  }

  useLayoutEffect(() => {
    purchase()
  }, [])

  if (!props.sale_page.is_free && !props.sale_page.is_external && !props.customer_subscribed) {
    return (
      <div className="done-view">
        <h3 className="title">
          {I18n.t("common.pay_the_payment")}
        </h3>
        <ServiceCheckoutForm
          stripe_key={props.stripe_key}
          purchase_data={purchase_data}
          company_name={props.sale_page.company_info.name}
          service_name={props.sale_page.product.name}
          price={props.sale_page.paying_amount_format}
          payment_type={props.sale_page.payment_type}
          function_access_id={props.function_access_id}
        />
      </div>
    )
  }

  if (props.sale_page.is_external) return <></>

  return (
    <div className="done-view">
      <h3 className="title">
        {I18n.t('common.thanks')}
      </h3>

      <CheckInLineBtn social_account_add_friend_url={props.add_friend_url}>
        <div className="message break-line-content">
          {I18n.t("online_service_purchases.service_content")}
          <br />
          <div dangerouslySetInnerHTML={{
             __html: I18n.t("online_service_purchases.please_check_in_channel", {
              channel: props.channel
             })
          }} />
        </div>
      </CheckInLineBtn>
    </div>
  )
}

export const CustomerPurchases = ({props}) => {
  const { social_user_id, customer_id, had_address } = props.social_customer;
  const [identified_customer, setIdentifiedCustomer] = useState(props.customer.is_identified ? { customer_id: customer_id, customer_verified: true } : null)
  const [is_customer_address_created, setCustomerAddressCreated] = useState(had_address)

  const handleCustomerAddressSubmit = async (address_details) => {
    const [error, response] = await CommonServices.update(
      {
        url: Routes.lines_update_customer_address_path({format: "json"}),
        data: {
          address_details,
          customer_id,
          social_service_user_id: social_user_id
        }
      }
    );

    if (response.status == 200) {
      setCustomerAddressCreated(true)
    }
  }

  if (!social_user_id && props.line_login_required) {
    return (
      <div className="sale-page">
        <CompanyHeader shop={props.sale_page.company_info || props.sale_page.shop}>
          <LineIdentificationView line_login_url={props.line_login_url} />
        </CompanyHeader>
      </div>
    )
  }

  if (identified_customer && props.is_customer_address_required && !is_customer_address_created) {
    return (
      <div className="sale-page">
        <CompanyHeader shop={props.sale_page.company_info || props.sale_page.shop}>
          <h3 className="centerize">
            {I18n.t("common.customer_address_view_title")}
          </h3>
          <AddressView handleSubmitCallback={handleCustomerAddressSubmit} />
        </CompanyHeader>
      </div>
    )
  }

  if (identified_customer && identified_customer.customer_verified) {
    return (
      <div className="sale-page">
        <CompanyHeader shop={props.sale_page.company_info || props.sale_page.shop}>
          <FinalPaidPage
            props={props}
            purchase_data={
              {
                slug: props.sale_page_slug,
                customer_id: identified_customer.customer_id
              }
            }
          />
        </CompanyHeader>
      </div>
    )
  }

  return (
    <div className="sale-page">
      <CompanyHeader shop={props.sale_page.company_info || props.sale_page.shop}>
        <CustomerIdentification
          social_customer={{
            social_user_id: social_user_id,
            customer_id: customer_id
          }}
          customer={props.customer}
          i18n={props.i18n}
          support_feature_flags={props.support_feature_flags}
          locale={props.locale}
          identifiedCallback={
            (customer) => {
              setIdentifiedCustomer({ customer_id: customer.customer_id, customer_verified: customer.customer_verified })
            }
          }
        />
      </CompanyHeader>
    </div>
  )
}

export default CustomerPurchases;
