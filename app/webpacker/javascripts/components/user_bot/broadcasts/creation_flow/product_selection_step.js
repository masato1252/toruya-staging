import React, { useEffect } from "react";
import ReactSelect from "react-select";

import I18n from 'i18n-js/index.js.erb';
import { useGlobalContext } from "./context/global_state";
import FlowStepIndicator from "./flow_step_indicator";
import CustomerWithTagsQuery from "./customer_with_tags_query";
import CustomerWithBirthdayQuery from "./customer_with_birthday_query";

var moment = require('moment-timezone');

const ProductSelectionStep = ({next, step, prev}) => {
  const { props, dispatch, query, query_type, selected_menu, selected_online_service, customers_count, fetchCustomersCount } = useGlobalContext()

  useEffect(() => {
    if (query_type === "all" || query_type === "vip_customers" || query_type === "active_customers") next()
      if (query_type === "customers_with_birthday") {
        dispatch({
          type: "SET_ATTRIBUTE",
          payload: {
          attribute: "query",
          value:  {
            operator: "and",
            filters: [
              {
                field: "birthday",
                condition: "age_range",
                value: [30, 35]
              },
              {
                field: "birthday",
                condition: "date_month_eq",
                value: moment().month() + 1
              }
            ]
          }
        }
      })
      }
  }, [])

  useEffect(() => {
    dispatch({
      type: "SET_ATTRIBUTE",
      payload: {
        attribute: "query",
        value:  {
          operator: "or",
          filters: _.uniqBy([
            ...(query?.filters || []),
            {
              field: "online_service_ids",
              condition: "contains",
              value: selected_online_service.id
            }
          ], 'value')
        }
      }
    })
  }, [selected_online_service])

  useEffect(() => {
    fetchCustomersCount()
  }, [query])

  const renderProductDropDown = () => {
    switch (query_type) {
      case "customers_with_birthday":
        return (
          <CustomerWithBirthdayQuery
            customers_count={customers_count}
            query={query}
            setQuery={(query_payload) => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "query",
                  value: query_payload
                }
              })
            }}
          />
        )
      case "customers_with_tags":
        return (
          <CustomerWithTagsQuery
            customer_tags={props.customer_tags}
            customers_count={customers_count}
            query={query}
            setQuery={(query_payload) => {
              dispatch({
                type: "SET_ATTRIBUTE",
                payload: {
                  attribute: "query",
                  value: query_payload
                }
              })
            }}
           />
        )
      case "menu":
        return (
          <>
            <div className="margin-around">
            <ReactSelect
              className="text-left"
              placeholder={I18n.t("common.select_a_menu")}
              value={ _.isEmpty(selected_menu) ? "" : selected_menu}
              options={props.menus}
              onChange={
                (menu) => {
                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "selected_menu",
                      value: menu
                    }
                  })

                  dispatch({
                    type: "SET_ATTRIBUTE",
                    payload: {
                      attribute: "query",
                      value:  {
                        operator: "or",
                        filters: [
                          {
                            field: "menu_ids",
                            condition: "contains",
                            value: menu.value
                          },
                        ]
                      }
                    }
                  })
                }
              }
            />
            </div>
            {selected_menu && (
              <div className="item-container">
                <div className="item-element">
                  <span>{I18n.t("user_bot.dashboards.broadcast_creation.approximate_customers_count")}</span>
                  <span className="item-data">{customers_count}</span>
                </div>
              </div>
            )}
            <a href='https://toruya.com/faq/broadcast_count-zero'>
              <i className='fa fa-question-circle' />{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_help_tips")}
            </a>
          </>
        )
      case "online_service":
      case "online_service_for_active_customers":
        return (
          <>
            <div className="margin-around">
              <ReactSelect
                className="text-left"
                Value={selected_online_service ? { label: selected_online_service.internal_name } : ""}
                defaultValue={selected_online_service ? { label: selected_online_service.internal_name } : ""}
                placeholder={I18n.t("common.select_a_service")}
                options={props.online_services}
                onChange={
                  (online_service_option)=> {
                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "selected_online_service",
                        value: online_service_option.value
                      }
                    })


                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "query",
                        value:  {
                          operator: "or",
                          filters: _.uniqBy([
                            ...(query?.filters || []),
                            {
                              field: "online_service_ids",
                              condition: "contains",
                              value: online_service_option.value.id
                            }
                          ], 'value')
                        }
                      }
                    })
                  }
                }
              />
            </div>
            <div className="field-header">{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_services")}</div>
            {query?.filters && <p className="margin-around desc">{I18n.t("user_bot.dashboards.online_service_creation.bundled_service_usage_desc")}</p>}
            {query?.filters?.map(condition => (
              <button
                key={condition.value}
                className="btn btn-gray mx-2 my-2"
                onClick={() =>
                  {
                    dispatch({
                      type: "SET_ATTRIBUTE",
                      payload: {
                        attribute: "query",
                        value:  {
                          operator: "or",
                          filters: query.filters.filter(item => item.value !== condition.value)
                        }
                      }
                    })
                  }
                }>
                {props.online_services.find(service => service.value.id == condition.value)?.label }
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
            <a href='https://toruya.com/faq/broadcast_count-zero'>
              <i className='fa fa-question-circle' />{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_help_tips")}
            </a>
          </>
        )
    }
  }

  return (
    <div className="form settings-flow centerize">
      <FlowStepIndicator step={step} />
      <h3 className="header centerize">
        {query_type === "menu" ? I18n.t("user_bot.dashboards.broadcast_creation.what_menu_do_you_want") : I18n.t("user_bot.dashboards.broadcast_creation.what_service_do_you_want")}
      </h3>
      {renderProductDropDown()}
      <div className="action-block">
        <button onClick={prev} className="btn btn-tarco">
          {I18n.t("action.prev_step")}
        </button>
        <button onClick={next} className="btn btn-yellow" disabled={!query?.filters?.length}>
          {I18n.t("action.next_step")}
        </button>
      </div>
    </div>
  )
}

export default ProductSelectionStep;
