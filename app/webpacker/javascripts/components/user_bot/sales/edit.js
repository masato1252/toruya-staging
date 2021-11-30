"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import ReactPlayer from 'react-player';
import ReactSelect from "react-select";
import _ from "lodash";

import { BottomNavigationBar, TopNavigationBar, CiricleButtonWithWord } from "shared/components"
import { SaleServices } from "user_bot/api"
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import { Template, HintTitle } from "shared/builders"
import WhyContentEdit from "components/user_bot/sales/why_content_edit";
import StaffEdit from "components/user_bot/sales/staff_edit";
import FlowEdit from "components/user_bot/sales/flow_edit";
import BenefitsEdit from "components/user_bot/sales/benefits_edit";
import FaqEdit from "components/user_bot/sales/faq_edit";
import ReviewsEdit from "components/user_bot/sales/reviews_edit";
import SellingEndTimeEdit from "components/user_bot/sales/selling_end_time_edit";
import SellingStartTimeEdit from "components/user_bot/sales/selling_start_time_edit";
import NormalPriceEdit from "components/user_bot/sales/normal_price_edit";
import SellingPriceEdit from "components/user_bot/sales/selling_price_edit";
import SellingNumberEdit from "components/user_bot/sales/selling_number_edit";
import I18n from 'i18n-js/index.js.erb';

const SalePageEdit =({props}) => {
  const [focus_field, setFocusField] = useState()
  const [template_variables, setTemplateVariables] = useState(props.sale_page.template_variables)
  const [why_content, setWhyContent] = useState(props.sale_page.content)
  const [staff, setStaff] = useState(props.sale_page.staff)
  const [flow, setFlow] = useState(props.sale_page.sections_context?.flow || props.sale_page.flow || ["", ""])
  const [benefits, setBenefits] = useState(props.sale_page.sections_context?.benefits || ["", ""])
  const [faq, setFaq] = useState(props.sale_page.sections_context?.faq || ["", ""])
  const [reviews, setReviews] = useState(props.sale_page.reviews || ["", ""])
  const [end_time, setEndTime] = useState(props.sale_page.end_time)
  const [start_time, setStartTime] = useState(props.sale_page.start_time)
  const [normal_price, setNormalPrice] = useState(props.sale_page.normal_price_option || {
    price_type: "cost",
    price_amount: null
  })
  const [selling_price, setSellingPrice] = useState(props.sale_page.selling_price_option)
  const [quantity, setQuantity] = useState(props.sale_page.quantity_option)

  const { register, watch, setValue, control, handleSubmit, formState } = useForm({
    defaultValues: {
      ...props.sale_page,
    }
  });

  const onSubmit = async (data) => {
    let error, response;
    let submittedData;

    switch(props.attribute) {
      case "quantity":
        submittedData = { quantity: quantity && quantity["quantity_value"] }
        break
      case "selling_price":
        submittedData = { selling_price: selling_price && selling_price['price_amount'] }
        break
      case "normal_price":
        submittedData = { normal_price: normal_price && normal_price['price_amount'] }
        break
      case "end_time":
        submittedData = { selling_end_at: end_time && end_time["end_time_date_part"] }
        break
          case "start_time":
        submittedData = { selling_start_at: start_time && start_time["start_time_date_part"] }
        break
      case "why_content":
        submittedData = { why_content: _.pick(why_content, "desc1", "desc2", "picture") }
        break
      case "staff":
        submittedData = { staff: _.pick(staff, "id", "picture", "introduction") }
        break
      case "flow":
        submittedData = { flow }
        break
      case "benefits":
        submittedData = { benefits }
        break
      case "reviews":
        submittedData = { reviews: reviews.map((review) => _.pick(review, "customer_name", "content", "picture", "filename")) }
        break
      case "faq":
        submittedData = { faq }
        break
      case "introduction_video_url":
        break
      case "sale_template_variables":
        submittedData = { sale_template_variables: template_variables }
        break
    }


    [error, response] = await SaleServices.update({
      sale_page_id: props.sale_page.id,
      data: _.assign( data, {
        attribute: props.attribute,
        ...submittedData
      })
    })

    window.location = response.data.redirect_to
  }

  const renderCorrespondField = () => {
    switch(props.attribute) {
      case "quantity":
        return (
          <SellingNumberEdit
            quantity={quantity}
            handleQuantityChange={setQuantity}
          />
        )
        break
      case "selling_price":
        return (
          <SellingPriceEdit
            price={selling_price}
            handlePriceChange={setSellingPrice}
          />
        )
        break
      case "normal_price":
        return (
          <NormalPriceEdit
            normal_price={normal_price}
            handleNormalPriceChange={setNormalPrice}
          />
        )
        break
      case "end_time":
        return (
          <SellingEndTimeEdit
            end_time={end_time}
            handleEndTimeChange={setEndTime}
          />
        )
        break
      case "start_time":
        return (
          <SellingStartTimeEdit
            start_time={start_time}
            handleStartTimeChange={setStartTime}
          />
        )
        break
      case "why_content":
        return (
          <WhyContentEdit
            product_content={why_content}
            handleContentChange={(attr, value) => {
              setWhyContent({
                ...why_content, [attr]: value
              })
            }}
            handlePictureChange={(picture, pictureDataUrl) => {
              setWhyContent({
                ...why_content, picture: picture[0], picture_url: pictureDataUrl
              })
            }}
          />
        )
        break
      case "staff":
        return (
          <StaffEdit
            staffs={props.staffs}
            selected_staff={staff}
            handleStaffChange={(attr, value) => {
              if (attr === "selected_staff") {
                setStaff(value)
              }
              else if (attr === "introduction") {
                setStaff({...staff, introduction: value})
              }
            }}
            handlePictureChange={(picture, pictureDataUrl) => {
              setStaff({
                ...staff, picture: picture[0], picture_url: pictureDataUrl
              })
            }}
          />
        )
        break
      case "flow":
        return (
          <>
            <h3 className="header centerize break-line-content">
              {I18n.t('user_bot.dashboards.sales.form.flow_header')}
            </h3>
            <FlowEdit
              flow_tips={props.flow_tips}
              flow={flow}
              handleFlowChange={(action) => {
                const payload = action.payload

                switch(action.type) {
                  case "SET_FLOW":
                    setFlow(flow.map((item, flowIndex) => payload.index == flowIndex ? payload.value : item))
                    break
                  case "ADD_FLOW":
                    setFlow([...flow, ""])
                    break
                  case "REMOVE_FLOW":
                    setFlow(flow.filter((_, index) => payload.index !== index))
                    break
                }}
              }
            />
          </>
        )
        break
      case "benefits":
        return (
          <>
            <h3 className="header centerize break-line-content">
              {I18n.t('user_bot.dashboards.sales.form.benefits_header')}
            </h3>
            <BenefitsEdit
              solution_type={props.sale_page.solution_type}
              benefits={benefits}
              handleBenefitsChange={(action) => {
                const payload = action.payload

                switch(action.type) {
                  case "SET_BENEFITS":
                    setBenefits(benefits.map((item, index) => payload.index == index ? payload.value : item))
                    break
                  case "ADD_BENEFIT":
                    setBenefits([...benefits, ""])
                    break
                  case "REMOVE_BENEFIT":
                    setBenefits(benefits.filter((_, index) => payload.index !== index))
                    break
                }}
              }
            />
          </>
        )
        break
      case "faq":
        return (
          <>
            <h3 className="header centerize break-line-content">
              {I18n.t('user_bot.dashboards.sales.form.faq_header')}
            </h3>
            <FaqEdit
              faq={faq}
              handleFaqChange={(action) => {
                const payload = action.payload

                switch(action.type) {
                  case "SET_FAQ":
                    setFaq(faq.map((item, index) => payload.index == index ? {...item, [payload.attr]: payload.value} : item))
                    break
                  case "ADD_FAQ":
                    setFaq([...faq, ""])
                    break
                  case "REMOVE_FAQ":
                    setFaq(faq.filter((_, index) => payload.index !== index))
                    break
                }}
              }
            />
          </>
        )
        break
      case "reviews":
        return (
          <>
            <h3 className="header centerize break-line-content">
              {I18n.t('user_bot.dashboards.sales.form.reviews_header')}
            </h3>
            <ReviewsEdit
              reviews={reviews}
              handleReviewChange={(action) => {
                const payload = action.payload

                switch(action.type) {
                  case "SET_REVIEW":
                    setReviews(reviews.map((item, index) => payload.index == index ? {...item, ...payload.value} : item))
                    break
                  case "ADD_REVIEW":
                    setReviews([...reviews, ""])
                    break
                  case "REMOVE_REVIEW":
                    setReviews(reviews.filter((_, index) => payload.index !== index))
                    break
                }}
              }
            />
          </>
        )
        break
      case "introduction_video_url":
        return (
          <>
            <div className="field-row">
              <input autoFocus={true} ref={register} name={props.attribute} placeholder={props.placeholder} className="extend" type="text" />
            </div>
            <div className='video-player-wrapper'>
              <ReactPlayer
                className='react-player'
                light={false}
                url={watch("introduction_video_url") || ""}
                width='100%'
                height='100%'
              />
            </div>
          </>
        );
        break
      case "sale_template_variables":
        return (
          <>
            <HintTitle template={props.sale_page.edit_template} focus_field={focus_field} />
            <SaleTemplateContainer
              shop={props.sale_page.company_info}
              product={props.sale_page.product}>
              <Template
                {...template_variables}
                template={props.sale_page.edit_template}
                product_name={props.sale_page.product.name}
                onBlur={(name, value) => {
                  setTemplateVariables({...template_variables, [name]: value})
                }}
                onFocus={(name) => setFocusField(name)}
              />
            </SaleTemplateContainer>
          </>
        );
        break
    }
  }

  return (
    <div className="form with-top-bar">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_sale_path(props.sale_page.id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t(`user_bot.dashboards.sales.form.${props.attribute}_title`)}
      />
      <div className="field-header">{I18n.t(`user_bot.dashboards.sales.form.${props.attribute}_subtitle`)}</div>
      <div className="centerize">
        {renderCorrespondField()}
      </div>
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

export default SalePageEdit
