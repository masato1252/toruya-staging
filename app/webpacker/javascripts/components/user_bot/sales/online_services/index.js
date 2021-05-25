"use strict";

import React from "react";
import SaleTemplateView from "components/user_bot/sales/online_services/sale_template_view";
import PriceBlock from "components/user_bot/sales/online_services/price_block";
import StaffView from "components/user_bot/sales/staff_view";
import FlowView from "components/user_bot/sales/flow_view";
import BenefitsView from "components/user_bot/sales/benefits_view";
import FaqView from "components/user_bot/sales/faq_view";
import WhyContentView from "components/user_bot/sales/why_content_view";
import I18n from 'i18n-js/index.js.erb';

const SaleOnlineService = ({product, social_account_add_friend_url, template, template_variables, content, staff, demo, dispatch, jump,
  price, normal_price, quantity, introduction_video, is_started, start_at, is_ended, purchase_url, preview, flow, payable, sections_context}) => {

  if (preview) {
    return (
      <div className="sale-page centerize">
        <SaleTemplateView
          company_info={product.company_info}
          product={product}
          demo={demo}
          template={template}
          template_variables={template_variables}
          introduction_video={introduction_video}
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
        />
      </div>
    )
  }
  return (
    <div className="sale-page centerize">
      <SaleTemplateView
        company_info={product.company_info}
        product={product}
        demo={demo}
        template={template}
        template_variables={template_variables}
        introduction_video={introduction_video}
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
      />

      <WhyContentView content={content} demo={demo} jumpTo={() => jump(9)} />
      <BenefitsView benefits={sections_context?.benefits} />
      <StaffView staff={staff} demo={demo} jumpTo={() => jump(10)} />
      <FaqView faq={sections_context?.faq} />
      <FlowView flow={flow} jump={jump} demo={demo} />

      <div className="apply-content content">
        <h3 className="header centerize">{I18n.t("common.apply_now")}</h3>

        <PriceBlock
          solution_type={product.solution_type}
          demo={demo}
          social_account_add_friend_url={social_account_add_friend_url}
          selling_price={price?.price_amount}
          normal_price={normal_price?.price_amount}
          quantity={quantity}
          is_started={is_started}
          is_ended={is_ended}
          purchase_url={purchase_url}
          payable={payable}
        />
      </div>

      <div className="shop-content content">
        <div><b>{product.company_info.name}</b></div>
        <div>{product.company_info.address}</div>
        <div><i className="fa fa-phone"></i> <a href={`tel:${product.company_info.phone_number}`}>{product.company_info.phone_number}</a></div>
      </div>
    </div>
  )
}

export default SaleOnlineService;
