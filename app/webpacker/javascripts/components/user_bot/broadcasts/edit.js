"use strict"

import React, { useRef, useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import moment from "moment-timezone";
import ReactSelect from "react-select";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, CustomerSelectionList } from "shared/components"
import { Translator, getMomentLocale } from "libraries/helper";
import { CommonServices } from "user_bot/api"
import CustomerWithTagsQuery from "user_bot/broadcasts/creation_flow/customer_with_tags_query";
import CustomerWithBirthdayQuery from "user_bot/broadcasts/creation_flow/customer_with_birthday_query";

let personalizeKeyword = "";

const BroadcastEdit =({props}) => {
  const locale = props.locale || 'ja';
  moment.locale(getMomentLocale(locale));

  const { register, watch, setValue, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.broadcast
    }
  });
  const textareaRef = useRef();
  const [cursorPosition, setCursorPosition] = useState(0)
  const [template, setTemplate] = useState(props.broadcast.content)
  const [scheduleAt, setScheduleAt] = useState(props.broadcast.schedule_at)
  const [query, setQuery] = useState(props.broadcast.query)
  const [selected_menu, setMenu] = useState(props.broadcast.query)
  const [selected_online_service, setService] = useState(props.broadcast.query)
  const [customers_count, setCustomerCount] = useState(0)
  const [selected_customers, setSelectedCustomers] = useState(props.candidate_customers?.filter(customer =>
    props.broadcast.receiver_ids?.includes(String(customer.id))
  ) || [])

  useEffect(() => {
    textareaRef.current?.focus()
  }, [template.length])

  useEffect(() => {
    fetchCustomersCount()
  }, [query])

  const fetchCustomersCount = async () => {
    if (query === null) return;
    if (query.filters.length === 0) return;

    const [_error, response] = await CommonServices.update(
      {
        url: Routes.customers_count_lines_user_bot_broadcasts_path(props.business_owner_id, {format: "json"}),
        data: {
          query: query,
          query_type: props.broadcast.query_type
        }
      }
    )

    setCustomerCount(response.data.customers_count)
  }

  const insertKeyword = (keyword) => {
    personalizeKeyword = keyword
    const newTemplate = template.substring(0, cursorPosition) + personalizeKeyword + template.substring(cursorPosition)
    setTemplate(newTemplate)
  }

  const submittedData = (data) => {
    let request_data;

    switch(props.attribute) {
      case "content":
        request_data  = { content: template }
        break
      case "schedule_at":
        request_data = { schedule_at: scheduleAt }
        break
      case "query":
        request_data = { query: query, query_type: props.broadcast.query_type }
      case "manual_assignment":
        request_data = { receiver_ids: selected_customers.map(customer => customer.id) }
        break
    }

    return request_data
  }

  const onSubmit = async (data) => {
    let error, response;

    [error, response] = await CommonServices.update({
      url: props.broadcast_update_path || Routes.lines_user_bot_broadcast_path(props.business_owner_id, props.broadcast.id, {format: 'json'}),
      data: _.assign( data, {
        attribute: props.attribute,
        business_owner_id: props.business_owner_id,
        ...submittedData()
      })
    })

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to;
    }
  }

  const handleCustomerToggle = (customerId) => {
    const customer = props.candidate_customers.find(c => c.id === customerId);
    if (!customer) return;

    setSelectedCustomers(prevSelected => {
      const isSelected = prevSelected.some(c => c.id === customerId);
      if (isSelected) {
        return prevSelected.filter(c => c.id !== customerId);
      } else {
        return [...prevSelected, customer];
      }
    });
  };

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "content":
        return (
          <>
            <div className="field-row">
              <textarea
                ref={textareaRef}
                autoFocus={true}
                className="extend with-border"
                value={template}
                onChange={(event) => {
                  setTemplate(event.target.value)
                }}
                onBlur={() => {
                  setCursorPosition(textareaRef.current.selectionStart)
                }}
                onClick={() => {
                  setCursorPosition(textareaRef.current.selectionStart)
                }}
              />
              <button className="btn btn-gray margin-around m-3" onClick={() => { insertKeyword("%{customer_name}") }}> {I18n.t("user_bot.dashboards.settings.custom_message.buttons.customer_name")} </button>
            </div>
            <div>
              <div className="preview-hint">{I18n.t("user_bot.dashboards.broadcast_creation.preview")}</div>
              <p className="margin-around p10 bg-gray rounded break-line-content">{Translator(template, {...props.message})}</p>
            </div>
          </>
        )
      case "schedule_at":
        return (
          <>
            <div className="field-row">
              <div className="margin-around m10 mt-0">
                <label>
                  <input
                    type="radio" name="schedule_at"
                    checked={scheduleAt == null}
                    onChange={
                      () => {
                        setScheduleAt(null)
                      }
                    }
                  />
                  {I18n.t("common.send_now_label")}
                </label>
              </div>
            </div>
            <div className="field-row">
              <div className="margin-around m10">
                <label>
                  <input
                    type="radio" name="send_later"
                    checked={scheduleAt !== null}
                    onChange={
                      () => {
                        setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))
                      }
                    }
                  />
                  <input
                    type="datetime-local"
                    value={scheduleAt || moment().format("YYYY-MM-DDTHH:mm")}
                    onClick={() => {
                      setScheduleAt(moment().format("YYYY-MM-DDTHH:mm"))
                    }}
                    onChange={(e) => {
                      setScheduleAt(e.target.value)
                    }}
                  />
                </label>
              </div>
            </div>
          </>
        )
      case "manual_assignment":
        return (
          <CustomerSelectionList
            candidateCustomers={props.candidate_customers}
            selectedCustomerIds={selected_customers.map(customer => customer.id)}
            onCustomerToggle={handleCustomerToggle}
            customerStatusType={props.customer_status_type}
          />
        )
      case "query":
        {
          switch (props.broadcast.query_type) {
            case "customers_with_birthday":
              return (
                <CustomerWithBirthdayQuery
                  customers_count={customers_count}
                  query={query}
                  setQuery={(query_payload) => {
                    setQuery(query_payload)
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
                    setQuery(query_payload)
                  }}
                  props={props}
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
                          setMenu(menu)
                          setQuery(
                            {
                              operator: "or",
                              filters: [
                                {
                                  field: "menu_ids",
                                  condition: "contains",
                                  value: menu.value
                                }
                              ]
                            }
                          )
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
                          setService(online_service_option.value)

                          setQuery(
                            {
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
                          )
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
                          setQuery(
                            {
                              operator: "or",
                              filters: query.filters.filter(item => item.value !== condition.value)
                            }
                          )
                        }
                      }>
                      {props.online_services.find(service => service.value.id == condition.value).label }
                    </button>
                  ))}
                  <hr />

                  {query?.filters && query.filters.length !== 0 && (
                    <div className="centerize">
                      <div className="flex justify-evenly my-4">
                        <span>{I18n.t("user_bot.dashboards.broadcast_creation.approximate_customers_count")}</span>
                        <span className="item-data">{customers_count}</span>
                      </div>
                    </div>
                  )}
                  {props.support_feature_flags.support_faq_display && (
                    <div className="centerize">
                      <a href='https://toruya.com/faq/broadcast_count-zero'>
                        <i className='fa fa-question-circle' />{I18n.t("user_bot.dashboards.broadcast_creation.broadcast_help_tips")}
                      </a>
                    </div>
                  )}
                </>
              )
          }
        }
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={props.previous_path || Routes.lines_user_bot_broadcasts_path(props.business_owner_id)}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t(`user_bot.dashboards.broadcasts.form.${props.attribute}_title`)}
            />
            <div className="field-header">{I18n.t(`user_bot.dashboards.broadcasts.form.${props.attribute}_subtitle`)}</div>
            {renderCorrespondField()}
            <BottomNavigationBar klassName="centerize">
              <span></span>
              <CircleButtonWithWord
                disabled={formState.isSubmitting}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>
      </div>
    </div>
  )
}

export default BroadcastEdit
