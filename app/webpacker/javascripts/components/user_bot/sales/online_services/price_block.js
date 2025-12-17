"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import { ServiceStartInfo, ServiceEndInfo, AddLineFriendInfo } from "shared/booking";

// price: {
//   price_types: ['free', 'one_time', 'multiple_times', 'month', 'year'],
//   price_amounts: {
//     one_time: {
//       amount: 3000
//     },
//     multiple_times: {
//       times: 3,
//       amount: 1000
//     },
//     month: {
//       amount: 3000
//     },
//     year: {
//       amount: 30000
//     }
//   }
// }
const NormalPriceBlock = ({amount, support_feature_flags}) => {
  if (!amount) return <></>;

  return (
    <div>
      <div className="normal-price">
        <div className="label">{I18n.t("common.normal_price_label")}</div>
        <div className="amount">{amount}<span className="price-with-tax">{I18n.t("common.unit")}{support_feature_flags?.support_tax_include_display ? `(${I18n.t("common.tax_included")})` : ""}</span></div>
      </div>

      <div className="margin-around">
        <i className="fa fa-arrow-down"></i>
      </div>
    </div>
  )
}

const PriceOntTimePaymentText = ({amount, support_feature_flags}) => {
  if (!amount) return <></>;

  return <div>{amount}<span className="price-with-tax">{I18n.t("common.unit")}{support_feature_flags?.support_tax_include_display ? `(${I18n.t("common.tax_included")})` : ""}</span></div>
}
const PriceMultipleTimesPaymnetText = ({times, amount, support_feature_flags}) => {
  if (!amount) return <></>;

  return (
    <div>
      {amount}<span className="price-with-tax">{I18n.t("common.unit")}{support_feature_flags?.support_tax_include_display ? `(${I18n.t("common.tax_included")})` : ""}</span>
      <span className="multiple">&nbsp;X&nbsp;</span>
      {times}<span className="small-text">{I18n.t('common.times')}</span>
    </div>
  )
}

const PriceBlock = ({
  demo,
  solution_type,
  price,
  normal_price,
  is_started,
  start_at,
  end_at,
  start_time,
  end_time,
  is_ended,
  purchase_url,
  social_account_add_friend_url,
  no_action,
  payable,
  is_external,
  support_feature_flags
}) => {

  const renderActions = (payment_type) => {
    if (no_action) return <></>

    if (demo) {
      return (
        <button className="btn btn-tarco btn-large btn-tall btn-icon watch">
          <i className="fas fa-credit-card"></i> {I18n.t(`action.sales.${solution_type}`)}
        </button>
      )
    }

    if (!payable && !is_external) {
      return (
        <div className="booking-info">
          <div className="unpayable-view">
            <div className="title">
              <h3>{I18n.t("common.preparing")}</h3>

              <div className="message break-line-content">
                {I18n.t("online_service_page.under_construction")}
              </div>
            </div>
          </div>
        </div>
      )
    }

    let url = new URL(purchase_url)
    url.searchParams.set('payment_type', payment_type);

    return (
      <a href={purchase_url ? url.href : "#"} className="btn btn-tarco btn-large btn-tall btn-icon watch" target="_blank">
        <i className="fas fa-credit-card"></i> {I18n.t(`action.sales.${solution_type}`)}
      </a>
    )
  }

  const isFree = () => {
    return (parseInt(
      price?.price_amounts?.one_time?.amount ||
      price?.price_amounts?.multiple_times?.amount ||
      price?.price_amounts?.month?.amount ||
      price?.price_amounts?.year?.amount ||
      0
    ) === 0) ||
      paymentType() == 'free'
  }

  // one time or multiple times
  const isSinglePrice = () => {
    return isFree() || price.price_types.length == 1
  }

  const paymentType = () => {
    return price.price_types[0] || 'free'
  }

  const hasPaymentType = (paymentType) => {
    return price?.price_types?.includes(paymentType);
  }

  if (!demo && is_ended) {
    return (
      <>
        <ServiceEndInfo />
        <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
      </>
    )
  }

  if (!demo && !is_started) {
    return (
      <>
        <ServiceStartInfo start_at={start_time} />
        <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
      </>
    )
  }

  if (isSinglePrice()) {
    return (
      <div className="product-price-block">
        <NormalPriceBlock amount={normal_price} support_feature_flags={support_feature_flags} />

        <div className="price">
          <div className="special-price">
            <div className="label">{I18n.t("common.today_price_label")}</div>
            {
              !isFree() && (
                <>
                  {hasPaymentType("month") && price?.price_amounts?.month?.amount && <h3 className="payment-type-title">{I18n.t("common.month_pay")}</h3>}
                  {hasPaymentType("year") && price?.price_amounts?.year?.amount && <h3 className="payment-type-title">{I18n.t("common.year_pay")}</h3>}
                  {hasPaymentType("one_time") && <PriceOntTimePaymentText amount={price?.price_amounts?.one_time?.amount} support_feature_flags={support_feature_flags} />}
                  {hasPaymentType("multiple_times") && <PriceMultipleTimesPaymnetText amount={price?.price_amounts?.multiple_times?.amount} times={price?.price_amounts?.multiple_times?.times} support_feature_flags={support_feature_flags} />}
                  {hasPaymentType("month") && <PriceOntTimePaymentText amount={price?.price_amounts?.month?.amount} support_feature_flags={support_feature_flags} />}
                  {hasPaymentType("year") && <PriceOntTimePaymentText amount={price?.price_amounts?.year?.amount} support_feature_flags={support_feature_flags} />}
                </>
              )
            }
            {isFree() && <div>{I18n.t("common.free_price")}</div>}
          </div>
        </div>

        {renderActions(paymentType())}
      </div>
    )
  }
  else {
    return (
      <div className="product-price-block">
        <NormalPriceBlock amount={normal_price} />

        {hasPaymentType("one_time") && price?.price_amounts?.one_time?.amount && (
          <div className="multiple-prices">
            <div className="price">
              <h3 className="payment-type-title">{I18n.t("common.one_time_pay")}</h3>
              <div className="special-price">
                <PriceOntTimePaymentText amount={price.price_amounts.one_time.amount} support_feature_flags={support_feature_flags} />
              </div>
            </div>

            {renderActions('one_time')}
          </div>
        )}

        {hasPaymentType("multiple_times") && price?.price_amounts?.multiple_times?.amount && price?.price_amounts?.multiple_times?.times && (
          <div className="multiple-prices">
            <div className="price">
              <h3 className="payment-type-title">{I18n.t("common.multiple_times_pay")}</h3>
              <div className="special-price">
                <PriceMultipleTimesPaymnetText amount={price.price_amounts.multiple_times.amount} times={price.price_amounts.multiple_times.times} support_feature_flags={support_feature_flags} />
              </div>
            </div>

            {renderActions('multiple_times')}
          </div>
        )}

        {hasPaymentType("month") && price?.price_amounts?.month?.amount && (
          <div className="multiple-prices">
            <div className="price">
              <h3 className="payment-type-title">{I18n.t("common.month_pay")}</h3>
              <div className="special-price">
                <PriceOntTimePaymentText amount={price.price_amounts.month.amount} support_feature_flags={support_feature_flags} />
              </div>
            </div>

            {renderActions('month')}
          </div>
        )}

        {hasPaymentType("year") && price?.price_amounts?.year?.amount && (
          <div className="multiple-prices">
            <div className="price">
              <h3 className="payment-type-title">{I18n.t("common.year_pay")}</h3>
              <div className="special-price">
                <PriceOntTimePaymentText amount={price.price_amounts.year.amount} support_feature_flags={support_feature_flags} />
              </div>
            </div>

            {renderActions('year')}
          </div>
        )}
      </div>
    )
  }
}

export default PriceBlock
