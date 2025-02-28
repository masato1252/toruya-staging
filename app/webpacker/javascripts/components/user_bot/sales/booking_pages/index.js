"use strict";

import React from "react";
import SaleTemplateView from "components/user_bot/sales/booking_pages/sale_template_view";
import PriceBlock from "components/user_bot/sales/booking_pages/price_block";
import StaffView from "components/user_bot/sales/staff_view";
import FlowView from "components/user_bot/sales/flow_view";
import BenefitsView from "components/user_bot/sales/benefits_view";
import ReviewsView from "components/user_bot/sales/reviews_view";
import FaqView from "components/user_bot/sales/faq_view";
import WhyContentView from "components/user_bot/sales/why_content_view";
import CompanyInfoView from "components/user_bot/sales/company_info_view";
import I18n from 'i18n-js/index.js.erb';

const SaleBookingPage = (
  {product, normal_price, social_account_add_friend_url, template, template_variables, content, staff, demo, dispatch, jump,
    shop, flow, preview, introduction_video_url, sections_context, solution_type, reviews, support_feature_flags, company_info}) => {

  if (preview) {
    return (
      <div className="sale-page centerize">
        <SaleTemplateView
          shop={shop}
          product={product}
          demo={demo}
          template={template}
          template_variables={template_variables}
          introduction_video_url={introduction_video_url}
          social_account_add_friend_url={social_account_add_friend_url}
          normal_price={normal_price}
          jump={jump}
          support_feature_flags={support_feature_flags}
        />

        <WhyContentView content={content} demo={demo} jumpTo={() => jump(4)} />
        <BenefitsView benefits={sections_context?.benefits} solution_type={solution_type} />
        <StaffView staff={staff} demo={demo} jumpTo={() => jump(5)} />
        <ReviewsView reviews={reviews} />
        <FaqView faq={sections_context?.faq} />
        <FlowView flow={flow} jump={jump} demo={demo} />
      </div>
    )
  }

  return (
    <div className="sale-page centerize">
      <SaleTemplateView
        shop={shop}
        product={product}
        demo={demo}
        template={template}
        template_variables={template_variables}
        introduction_video_url={introduction_video_url}
        social_account_add_friend_url={social_account_add_friend_url}
        normal_price={normal_price}
        jump={jump}
        support_feature_flags={support_feature_flags}
      />

      <WhyContentView content={content} demo={demo} jumpTo={() => jump(4)} />
      <BenefitsView benefits={sections_context?.benefits} solution_type={solution_type} />
      <StaffView staff={staff} demo={demo} jumpTo={() => jump(5)} />
      <ReviewsView reviews={reviews} />
      <FaqView faq={sections_context?.faq} />
      <FlowView flow={flow} jump={jump} demo={demo} />

      <div className="apply-content content">
        <h3 className="header centerize">{I18n.t("common.apply_now")}</h3>

        <PriceBlock
          product={product}
          demo={demo}
          normal_price={normal_price?.price_amount}
        />
      </div>

      <CompanyInfoView info={company_info} className="shop-content content" />
    </div>
  )
}

export default SaleBookingPage;
