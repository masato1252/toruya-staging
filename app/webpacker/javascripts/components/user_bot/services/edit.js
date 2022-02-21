"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import ReactSelect from "react-select";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CiricleButtonWithWord } from "shared/components"
import { OnlineServices } from "user_bot/api"
import BookingSaleTemplateView from "components/user_bot/sales/booking_pages/sale_template_view";
import ServiceSaleTemplateView from "components/user_bot/sales/online_services/sale_template_view";

import EditSolutionInput from "shared/edit/solution_input";
import EditMessageTemplate from "user_bot/services/edit_message_template";

const OnlineServiceEdit =({props}) => {
  const [sale_page, setSalePage] = useState(props.service.upsell_sale_page)
  const [end_time, setEndTime] = useState(props.service.end_time)
  const [start_time, setStartTime] = useState(props.service.start_time)
  const [message_template, setMessageTemplate] = useState(props.message_template)

  const { register, watch, setValue, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.service,
      solution_type: null
    }
  });

  const onDemoMessage = async (data) => {
    let error, response;

    [error, response] = await OnlineServices.demo_message({
      online_service_id: props.service.id,
      data: _.assign( data, { attribute: props.attribute, upsell_sale_page_id: sale_page?.id, end_time, start_time, message_template })
    })

    window.location = response.data.redirect_to
  }

  const onSubmit = async (data) => {
    let error, response;

    [error, response] = await OnlineServices.update({
      online_service_id: props.service.id,
      data: _.assign( data, { attribute: props.attribute, upsell_sale_page_id: sale_page?.id, end_time, start_time, message_template })
    })

    window.location = response.data.redirect_to
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "name":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register({ required: true })} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
          </>
        );
        break
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
                      company_type: company.type,
                      company_id: company.id
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
            <div className="margin-around centerize">
              <button className="btn btn-tarco margin-around m-3" onClick={handleSubmit(onDemoMessage)}>
                {I18n.t("user_bot.dashboards.settings.custom_message.buttons.send_me_mock_message")}
              </button>
            </div>
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
                          introduction_video={sale_page.introduction_video}
                          price={sale_page.price}
                          normal_price={sale_page.normal_price}
                          no_action={true}
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
                          upsell_sale_page_id: null,
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
                {I18n.t("sales.sale_now")}
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
          </div>
        )
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_service_path(props.service.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t(`user_bot.dashboards.services.form.${props.attribute}_title`)}
      />
      <div className="field-header">{I18n.t(`user_bot.dashboards.services.form.${props.attribute}_title`)}</div>
      {renderCorrespondField()}
      {props.attribute !== 'company' && (
        <BottomNavigationBar klassName="centerize">
          <span></span>
          <CiricleButtonWithWord
            disabled={formState.isSubmitting}
            onHandle={handleSubmit(onSubmit)}
            icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
            word={I18n.t("action.save")}
          />
        </BottomNavigationBar>
      )}
    </div>
  )
}

export default OnlineServiceEdit
