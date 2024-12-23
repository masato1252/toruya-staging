"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import ReactSelect from "react-select";
import _ from "lodash";

import I18n from 'i18n-js/index.js.erb';
import { BottomNavigationBar, TopNavigationBar, CircleButtonWithWord, EndOnMonthRadio, EndOnDaysRadio, EndAtRadio, NeverEndRadio, SubscriptionRadio } from "shared/components"
import { OnlineServices } from "user_bot/api"
import BookingSaleTemplateView from "components/user_bot/sales/booking_pages/sale_template_view";
import ServiceSaleTemplateView from "components/user_bot/sales/online_services/sale_template_view";

import EditSolutionInput from "shared/edit/solution_input";
import EditMessageTemplate from "user_bot/services/edit_message_template";
import EditTextarea from "shared/edit/textarea_input";
import EditUrlInput from "shared/edit/url_input";
import OnlineServicePage from "user_bot/services/online_service_page";
import LineCardPreview from "shared/line_card_preview";

const OnlineServiceEdit =({props}) => {
  const [sale_page, setSalePage] = useState(props.service.upsell_sale_page)
  const [end_time, setEndTime] = useState(props.service.end_time)
  const [start_time, setStartTime] = useState(props.service.start_time)
  const [bundled_services, setBundledServices] = useState(props.service.bundled_services)
  const [message_template, setMessageTemplate] = useState(props.message_template)

  const { register, watch, setValue, handleSubmit, formState, errors } = useForm({
    defaultValues: {
      ...props.service,
      customer_address_required: String(props.service.customer_address_required),
    }
  });

  const requestData = (data) => {
    let request_data;

    request_data  = _.assign(data, { id: props.service.id, business_owner_id: props.business_owner_id, attribute: props.attribute, upsell_sale_page_id: sale_page?.id, end_time, start_time, bundled_services })
    if (props.attribute == "message_template") request_data = { ...request_data, message_template, business_owner_id: props.business_owner_id }

    return request_data
  }

  const onSubmit = async (data) => {
    let error, response;

    if (props.attribute == "message_template" && !message_template.picture_url.length && !message_template.picture) return;

    [error, response] = await OnlineServices.update({
      online_service_id: props.service.id,
      data: requestData(data)
    })

    if (error) {
      toastr.error(error.response.data.error_message)
    }
    else {
      window.location = response.data.redirect_to;
    }
  }

  const bundled_service_end_time_options = (bundled_service) => {
    return props.bundled_service_candidates.find(candidate_service => candidate_service.value.id == bundled_service.id).value.end_time_options;
  }

  const set_end_time_type = ({bundled_service, end_time_type}) => {
    setBundledServices(
      bundled_services.map(bundled_service_item => (
        bundled_service_item.id == bundled_service.id ? (
          {
            id: bundled_service_item.id, label: bundled_service_item.label, end_time: {
              end_type: end_time_type
            }
          }
        ) :
        {...bundled_service_item}
      )
      )
    )
  }

  const set_end_time_value = ({bundled_service, end_time_type, end_time_value_key, end_time_value}) => {
    setBundledServices(
      bundled_services.map(bundled_service_item => (
        bundled_service_item.id == bundled_service.id ? (
          {
            id: bundled_service_item.id, label: bundled_service_item.label, end_time: {
              end_type: end_time_type,
              [end_time_value_key || end_time_type]: end_time_value
            }
          }
        ) :
        {...bundled_service_item}
      ))
    )
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "internal_name":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register({ required: true })} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
            <p className="centerize desc margin-around" dangerouslySetInnerHTML={{ __html: I18n.t("user_bot.dashboards.services.form.internal_name_desc_html") }} />
          </>
        )
      case "name":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register({ required: true })} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
          </>
        );
      case "note":
        return (
          <EditTextarea register={register} errors={errors} watch={watch} name={props.attribute} placeholder={props.placeholder} />
        )
      case "external_purchase_url":
        return (
          <EditUrlInput register={register} errors={errors} name={props.attribute} placeholder={props.placeholder} />
        )
      case "content_url":
        return (
          <EditSolutionInput
            solutions={props.solutions}
            attribute='content_url'
            solution_type={watch("solution_type")}
            placeholder={props.placeholder}
            register={register}
            errors={errors}
            watch={watch}
            setValue={setValue}
          />
        )
      case "bundled_services":
        return (
          <div className="centerize">
            <div className="margin-around">
              <label className="text-align-left">
                <ReactSelect
                  placeholder={I18n.t("user_bot.dashboards.online_service_creation.select_bundler_product")}
                  value={ _.isEmpty(bundled_services) ? "" : { label: bundled_services[bundled_services.length - 1].label }}
                  options={props.bundled_service_candidates}
                  onChange={
                    (service) => {
                      setBundledServices(
                        _.uniqBy([...bundled_services, { id: service.value.id, label: service.label, end_time: {} }], 'id')
                      )
                    }
                  }
                />
              </label>
            </div>

            {bundled_services.length !== 0 && <div className="field-header">{I18n.t("user_bot.dashboards.online_service_creation.bundled_services")}</div>}

            <div className="margin-around">
              {bundled_services.length !== 0 && <p className="desc">{I18n.t("user_bot.dashboards.online_service_creation.bundled_service_usage_desc")}</p>}

              {bundled_services.map(bundled_service => (
                <button
                  key={bundled_service.id}
                  className="btn btn-gray mx-2 my-2"
                  onClick={() => {
                    setBundledServices(
                      bundled_services.filter(item => item.id !== bundled_service.id)
                    )
                  }}>
                  {bundled_service.label}
                </button>
              ))}
            </div>

            {bundled_services.length !== 0 && <div className="field-header">{I18n.t("user_bot.dashboards.services.form.bundled_services_expiration")}</div>}
            <div className="margin-around">
              {bundled_services.map((bundled_service, index) => (
                <div key={bundled_service.id}>
                  <h3 key={bundled_service.id}> {bundled_service.label}</h3>

                  {bundled_service_end_time_options(bundled_service).includes('end_at') && (
                    <EndAtRadio
                      prefix={bundled_service.id}
                      end_time={bundled_service.end_time}
                      set_end_time_type={() => {
                        set_end_time_type({bundled_service, end_time_type: 'end_at'})
                      }}
                      set_end_time_value={(end_time_value) => {
                        set_end_time_value({bundled_service, end_time_type: 'end_at', end_time_value_key: 'end_time_date_part', end_time_value})
                      }}
                    />
                  )}

                  {bundled_service_end_time_options(bundled_service).includes('end_on_days') && (
                    <EndOnDaysRadio
                      prefix={bundled_service.id}
                      end_time={bundled_service.end_time}
                      set_end_time_type={() => {
                        set_end_time_type({bundled_service, end_time_type: 'end_on_days'})
                      }}
                      set_end_time_value={(end_time_value) => {
                        set_end_time_value({bundled_service, end_time_type: 'end_on_days', end_time_value})
                      }}
                    />
                  )}

                  {bundled_service_end_time_options(bundled_service).includes('end_on_months') && (
                    <EndOnMonthRadio
                      prefix={bundled_service.id}
                      end_time={bundled_service.end_time}
                      set_end_time_type={() => {
                        set_end_time_type({bundled_service, end_time_type: 'end_on_months'})
                      }}
                      set_end_time_value={(end_time_value) => {
                        set_end_time_value({bundled_service, end_time_type: 'end_on_months', end_time_value})
                      }}
                    />
                  )}

                  {bundled_service_end_time_options(bundled_service).includes('never') && (
                    <NeverEndRadio
                      prefix={bundled_service.id}
                      end_time={bundled_service.end_time}
                      set_end_time_type={() => {
                        set_end_time_type({bundled_service, end_time_type: 'never'})
                      }}
                    />
                  )}

                  {bundled_service_end_time_options(bundled_service).includes('subscription') && (
                    <SubscriptionRadio
                      prefix={bundled_service.id}
                      end_time={bundled_service.end_time}
                      set_end_time_type={() => {
                        set_end_time_type({bundled_service, end_time_type: 'subscription'})
                      }}
                    />
                  )}
                  {bundled_services.length !== index + 1 && <hr className="extend my-4" />}
                </div>
              ))}
            </div>
          </div>
        )
      case "customer_address_required":
        return (
          <>
            <label className="field-row flex-start">
              <input name="customer_address_required" type="radio" value="true" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.services.form.customer_address_required_label")}
            </label>
            <label className="field-row flex-start">
              <input name="customer_address_required" type="radio" value="false" ref={register({ required: true })} />
              {I18n.t("user_bot.dashboards.services.form.not_customer_address_required_label")}
            </label>
          </>
        )
      case "company":
        return (
          <div className="centerize">
            {props.companies.map(company => (
              <button
                key={company.label}
                onClick={async () => {
                  const [error, response] = await OnlineServices.update({
                    online_service_id: props.service.id,
                    data: _.assign( {
                      id: props.service.id,
                      company_type: company.type,
                      company_id: company.id,
                      business_owner_id: props.business_owner_id
                    }, { attribute: props.attribute })
                  })

                  window.location = response.data.redirect_to
                }}
                className="btn btn-tarco btn-extend btn-tall margin-around m10"
              >
                {company.label}
              </button>
            ))}
          </div>
        )
      case "message_template":
        return (
          <>
            <EditMessageTemplate
              service_name={props.service.name}
              message_template={message_template}
              handleMessageTemplateChange={(attr, value) => {
                setMessageTemplate({...message_template, [attr]: value})
              }}
              handlePictureChange={(picture, pictureDataUrl) => {
                setMessageTemplate({
                  ...message_template, picture: picture[0], picture_url: pictureDataUrl
                })
              }}
            />
          </>
        )
      case "upsell_sale_page":
        return (
          <div className="margin-around">
            <label className="text-align-left">
              <ReactSelect
                placeholder={I18n.t("user_bot.dashboards.online_service_creation.select_upsell_product")}
                value={ _.isEmpty(sale_page) ? "" : { label: sale_page.label }}
                options={props.upsell_sales}
                onChange={
                  (page) => {
                    setSalePage(page.value)
                  }
                }
              />
            </label>

            {
              !_.isEmpty(sale_page) && (
                <div className="centerize">
                  {sale_page.start_time}<br />
                  {sale_page.end_time}

                  <div className="sale-page margin-around">
                    {
                      sale_page.product_type === 'BookingPage' ? (
                        <BookingSaleTemplateView
                          shop={sale_page.shop}
                          product={sale_page.product}
                          template={sale_page.template}
                          template_variables={sale_page.template_variables}
                          no_action={true}
                        />
                      ) : (
                        <ServiceSaleTemplateView
                          company_info={sale_page.product.company_info}
                          product={sale_page.product}
                          template={sale_page.template}
                          template_variables={sale_page.template_variables}
                          introduction_video_url={sale_page.introduction_video_url}
                          price={sale_page.price}
                          normal_price={sale_page.normal_price}
                          no_action={true}
                          is_started={sale_page.is_started}
                          start_at={sale_page.start_time}
                          is_ended={sale_page.is_ended}
                        />
                      )
                    }
                  </div>
                </div>
              )
            }

            {
              props.service.upsell_sale_page_id && (
                <div className="margin-around centerize">
                  <button
                    onClick={async () => {
                      const [error, response] = await OnlineServices.update({
                        online_service_id: props.service.id,
                        data: _.assign( {
                          id: props.service.id,
                          upsell_sale_page_id: 0,
                          business_owner_id: props.business_owner_id
                        }, { attribute: props.attribute })
                      })

                      window.location = response.data.redirect_to
                    }}
                    className="btn btn-orange btn-tall margin-around m10"
                  >
                    {I18n.t("action.delete2")}
                  </button>
                </div>
              )
            }
          </div>
        )
        break;
      case "start_time":
        return (
          <div className="centerize">
            <div className="margin-around">
              <label className="">
                <input name="start_type" type="radio" value="now"
                  checked={start_time.start_type === "now"}
                  onChange={() => {
                    setStartTime({
                      start_type: "now",
                    })
                  }}
                />
                {I18n.t("common.right_away_after_purchased")}
              </label>
            </div>

            <div className="margin-around">
              <label className="">
                <div>
                  <input name="start_type" type="radio" value="start_at"
                    checked={start_time.start_type === "start_at"}
                    onChange={() => {
                      setStartTime({
                        start_type: "start_at"
                      })
                    }}
                  />
                  {I18n.t("sales.start_at")}
                </div>
                {start_time.start_type === "start_at" && (
                  <input
                    name="start_time_date_part"
                    type="date"
                    value={start_time.start_time_date_part || ""}
                    onChange={(event) => {
                      setStartTime({
                        start_type: "start_at",
                        start_time_date_part: event.target.value
                      })
                    }}
                  />
                )}
              </label>
            </div>
          </div>
        )
        break;
      case "end_time":
        return (
          <div className="centerize">
            <div className="margin-around">
              <label className="">
                <div>
                  <input
                    name="end_type" type="radio" value="end_on_days"
                    checked={end_time.end_type === "end_on_days"}
                    onChange={() => {
                      setEndTime({
                        end_type: "end_on_days"
                      })
                    }}
                  />
                  {I18n.t("user_bot.dashboards.online_service_creation.expire_after_n_days")}
                </div>
                {end_time.end_type === "end_on_days" && (
                  <>
                    {I18n.t("user_bot.dashboards.online_service_creation.after_bought")}
                    <input
                      type="tel"
                      value={end_time.end_on_days || ""}
                      onChange={(event) => {
                        setEndTime({
                          end_type: "end_on_days",
                          end_on_days: event.target.value
                        })
                      }} />
                      {I18n.t("user_bot.dashboards.online_service_creation.after_n_days")}
                    </>
                )}
              </label>
            </div>

            <div className="margin-around">
              <label className="">
                <div>
                  <input name="end_type" type="radio" value="end_at"
                    checked={end_time.end_type === "end_at"}
                    onChange={() => {
                      setEndTime({
                        end_type: "end_at"
                      })
                    }}
                  />
                  {I18n.t("user_bot.dashboards.online_service_creation.expire_at")}
                </div>
                {end_time.end_type === "end_at" && (
                  <input
                    name="end_time_date_part"
                    type="date"
                    value={end_time.end_time_date_part || ""}
                    onChange={(event) => {
                      setEndTime({
                        end_type: "end_at",
                        end_time_date_part: event.target.value
                      })
                    }}
                  />
                )}
              </label>
            </div>

            <div className="margin-around">
              <label className="">
                <input name="end_type" type="radio" value="never"
                  checked={end_time.end_type === "never"}
                  onChange={() => {
                    setEndTime({
                      end_type: "never",
                    })
                  }}
                />
                {I18n.t("user_bot.dashboards.online_service_creation.never_expire")}
              </label>
            </div>
            <div className="warning">
              {I18n.t("user_bot.dashboards.sales.online_service_creation.end_time_changes_warning")}
            </div>
          </div>
        )
    }
  }

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-6 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={
                <a href={props.back_path}>
                  <i className="fa fa-angle-left fa-2x"></i>
                </a>
              }
              title={I18n.t(`user_bot.dashboards.services.form.${props.attribute}_title`)}
            />
            <div className="field-header">{I18n.t(`user_bot.dashboards.services.form.${props.attribute}_subtitle`)}</div>
            {renderCorrespondField()}
            {props.attribute !== 'company' && (
              <BottomNavigationBar klassName="centerize">
                <span></span>
                <CircleButtonWithWord
                  disabled={formState.isSubmitting}
                  onHandle={handleSubmit(onSubmit)}
                  icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                  word={I18n.t("action.save")}
                />
              </BottomNavigationBar>
            )}
          </div>
        </div>
        <div className="col-sm-6 px-0 hidden-xs preview-view">
            {
              ['name', 'content_url', 'note', 'upsell_sale_page'].includes(props.attribute) && (
                <div className="fake-mobile-layout">
                  <OnlineServicePage
                    company_info={props.service.company_info}
                    name={watch('name') || props.service.name}
                    solution_type={props.service.solution_type}
                    note={watch('note') || props.service.note}
                    content_url={watch('content_url') || props.service.content_url}
                    upsell_sale_page={sale_page || props.service.upsell_sale_page}
                    light={false}
                  />
                </div>
              )
            }
          {
            ['message_template'].includes(props.attribute) && (
              <div className="fake-mobile-layout">
                <div className="line-chat-background">
                  <LineCardPreview
                    picture_url={message_template?.picture_url?.length ? message_template.picture_url : props.default_picture_url}
                    title={props.service.name}
                    desc="Dummy data"
                    actions={
                      <div className="btn line-button btn-extend with-wording only-word">
                        Dummy button
                      </div>
                    }
                  />
                </div>
              </div>
            )
          }
        </div>
      </div>
    </div>
  )
}

export default OnlineServiceEdit
