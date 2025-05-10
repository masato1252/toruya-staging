import React from "react"
import _, { set } from "lodash"

import I18n from 'i18n-js/index.js.erb';

const CustomerWithBirthdayQuery = ({customers_count, query, setQuery, props}) => {
    return (
      <>
        <div className="margin-around centerize">
          <div className="margin-around">
            {I18n.t("common.age")}
            <input
              className="w-10"
              type="tel"
              value={query?.filters[0]?.value[0] || ""}
              onChange={
                (e) => {
                  setQuery({
                    operator: "and",
                    filters: [
                      {
                        field: "birthday",
                        condition: "age_range",
                        value: [parseInt(e.target.value), parseInt(e.target.value) + 5]
                      },
                      ...(query.filters.slice(1)),
                    ]
                  })
              }}
                /> ~
              <input
                className="w-10"
                type="tel"
                value={query?.filters[0]?.value[1] || ""}
                onChange={
                  (e) => {
                    setQuery({
                      operator: "and",
                      filters: [
                        {
                          field: "birthday",
                          condition: "age_range",
                          value: [parseInt(query.filters[0].value[0]), parseInt(e.target.value)]
                        },
                        query.filters[1],
                      ]
                    })
                  }}
              />
              {I18n.t("common.years_old")}
            </div>
            {I18n.t("common.birthday_month")}
            <select
              value={query?.filters[1]?.value || ""}
              onChange={
                (e) => {
                  setQuery({
                    operator: "and",
                    filters: [
                      query.filters[0],
                      {
                        field: "birthday",
                        condition: "date_month_eq",
                        value: parseInt(e.target.value)
                      }
                    ]
                  })
                }}
            >
            {[...Array(12)].map((_, i) => (
              <option key={i + 1} value={i + 1}>{i + 1}</option>
            ))}
          </select>
          {I18n.t("common.month")}
          <div className="field-header mt-2">{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_services")}</div>
          {query?.filters && query.filters.length !== 0 && (
            <div className="centerize">
              <div className="flex justify-evenly my-4">
                <span>{I18n.t("user_bot.dashboards.broadcast_creation.approximate_customers_count")}</span>
                <span className="item-data">{customers_count}</span>
              </div>
            </div>
          )}
          {props.support_feature_flags.support_faq_display && (
            <a href='https://toruya.com/faq/broadcast_count-zero'>
              <i className='fa fa-question-circle' />{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_help_tips")}
            </a>
          )}
        </div>
      </>
    )
}

export default CustomerWithBirthdayQuery