import React from "react"
import _ from "lodash"

import I18n from 'i18n-js/index.js.erb';

const CustomerWithTagsQuery = ({customer_tags, customers_count, query, setQuery, props}) => {
    return (
      <>
        <div className="margin-around centerize">
          {customer_tags.map(tag => (
            <button
              key={tag}
              className="btn btn-gray mx-2 my-2"
              onClick={() => {
                setQuery({
                  operator: "and",
                  filters: _.uniqBy([
                    ...(query?.filters || []),
                    {
                      field: "tags",
                      condition: "contains",
                      value: tag
                    }
                  ], 'value')
                })
              }}>
              {tag}
            </button>
          ))}
          {customer_tags.length === 0 && <p className="margin-around desc warning">{I18n.t("user_bot.dashboards.broadcast_creation.customers_with_tags_no_data_desc")}</p>}
        </div>

        <div className="field-header">{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_services")}</div>
        {query?.filters && <p className="margin-around desc">{I18n.t("user_bot.dashboards.online_service_creation.bundled_service_usage_desc")}</p>}
        <div className="margin-around centerize">
          {query?.filters?.map(condition => (
            <button
              key={condition.value}
              className="btn btn-gray mx-2 my-2"
              onClick={() =>
                {
                  setQuery({
                    operator: "and",
                    filters: query.filters.filter(item => item.value !== condition.value)
                  })
                }
              }>
              {condition.value}
            </button>
          ))}

        <hr className="my-4"/>
          {query?.filters && query.filters.length !== 0 && (
            <div className="centerize">
              <div className="flex justify-evenly my-4">
                <span>{I18n.t("user_bot.dashboards.broadcast_creation.approximate_customers_count")}</span>
                <span className="item-data">{customers_count}</span>
              </div>
            </div>
          )}
          {props?.support_feature_flags.support_faq_display && (
            <a href='https://toruya.com/faq/broadcast_count-zero'>
              <i className='fa fa-question-circle' />{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_help_tips")}
            </a>
          )}
        </div>
      </>
    )
}

export default CustomerWithTagsQuery
