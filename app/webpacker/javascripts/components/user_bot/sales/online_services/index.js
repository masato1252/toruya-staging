"use strict";

import React from "react";
import SaleTemplateView from "components/user_bot/sales/online_services/sale_template_view";
import PriceBlock from "components/user_bot/sales/online_services/price_block";
import StaffView from "components/user_bot/sales/staff_view";
import FlowView from "components/user_bot/sales/flow_view";
import BenefitsView from "components/user_bot/sales/benefits_view";
import ReviewsView from "components/user_bot/sales/reviews_view";
import FaqView from "components/user_bot/sales/faq_view";
import WhyContentView from "components/user_bot/sales/why_content_view";
import CompanyInfoView from "components/user_bot/sales/company_info_view";
import I18n from 'i18n-js/index.js.erb';

const SaleOnlineService = ({product, social_account_add_friend_url, template, template_variables, content, staff, demo, dispatch, jump,
  price, normal_price, quantity, introduction_video_url, is_started, start_at, is_ended, purchase_url, preview, flow, payable, sections_context, solution_type, reviews, is_external, support_feature_flags, company_info}) => {

  if (preview) {
    return (
      <div className="sale-page centerize">
        <SaleTemplateView
          company_info={company_info}
          product={product}
          demo={demo}
          template={template}
          template_variables={template_variables}
          introduction_video_url={introduction_video_url}
          social_account_add_friend_url={social_account_add_friend_url}
          jump={jump}
          price={price}
          normal_price={normal_price}
          quantity={quantity}
          start_at={start_at}
          is_started={is_started}
          is_ended={is_ended}
          purchase_url={purchase_url}
          payable={payable}
          is_external={is_external}
          support_feature_flags={support_feature_flags}
        />

        <WhyContentView content={content} demo={demo} jumpTo={() => jump(9)} />
        <BenefitsView benefits={sections_context?.benefits} solution_type={solution_type} />
        <StaffView staff={staff} demo={demo} jumpTo={() => jump(10)} />
        <ReviewsView reviews={reviews} />
        <FaqView faq={sections_context?.faq} />
        <FlowView flow={flow} jump={jump} demo={demo} />
      </div>
    )
  }
  return (
    <div className="sale-page centerize">
      <SaleTemplateView
        company_info={company_info}
        product={product}
        demo={demo}
        template={template}
        template_variables={template_variables}
        introduction_video_url={introduction_video_url}
        social_account_add_friend_url={social_account_add_friend_url}
        jump={jump}
        price={price}
        normal_price={normal_price}
        quantity={quantity}
        start_at={start_at}
        is_started={is_started}
        is_ended={is_ended}
        purchase_url={purchase_url}
        payable={payable}
        is_external={is_external}
        support_feature_flags={support_feature_flags}
      />

      <WhyContentView content={content} demo={demo} jumpTo={() => jump(9)} />
      <BenefitsView benefits={sections_context?.benefits} solution_type={solution_type} />
      <StaffView staff={staff} demo={demo} jumpTo={() => jump(10)} />
      <ReviewsView reviews={reviews} />
      <FaqView faq={sections_context?.faq} />
      <FlowView flow={flow} jump={jump} demo={demo} />

      <div className="apply-content content">
        <h3 className="header centerize">{I18n.t("common.apply_now")}</h3>

        <PriceBlock
          solution_type={product.solution_type}
          demo={demo}
          social_account_add_friend_url={social_account_add_friend_url}
          price={price}
          normal_price={normal_price?.price_amount}
          quantity={quantity}
          is_started={is_started}
          is_ended={is_ended}
          purchase_url={purchase_url}
          payable={payable}
          is_external={is_external}
          support_feature_flags={support_feature_flags}
        />
      </div>

      <CompanyInfoView info={company_info} className="shop-content content" />
    </div>
  )
}

export default SaleOnlineService;
