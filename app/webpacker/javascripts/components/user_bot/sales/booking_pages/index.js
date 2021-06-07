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
import I18n from 'i18n-js/index.js.erb';

const SaleBookingPage = (
  {product, social_account_add_friend_url, template, template_variables, content, staff, demo, dispatch, jump,
    shop, flow, preview, introduction_video, sections_context, solution_type, reviews}) => {

  if (preview) {
    return (
      <div className="sale-page centerize">
        <SaleTemplateView
          shop={shop}
          product={product}
          demo={demo}
          template={template}
          template_variables={template_variables}
          introduction_video={introduction_video}
          social_account_add_friend_url={social_account_add_friend_url}
          jump={jump}
        />
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
        introduction_video={introduction_video}
        social_account_add_friend_url={social_account_add_friend_url}
        jump={jump}
      />

      <WhyContentView content={content} demo={demo} jumpTo={() => jump(4)} />
      <BenefitsView benefits={sections_context?.benefits} solution_type={solution_type} />
      <StaffView staff={staff} demo={demo} jumpTo={() => jump(5)} />
      <ReviewsView reviews={reviews} />
      <FaqView faq={sections_context?.faq} />
      <FlowView flow={flow} jump={jump} demo={demo} />

      <div className="apply-content content">
        <h3 className="header centerize">{I18n.t("common.apply_now")}</h3>

        <PriceBlock product={product} demo={demo} />
      </div>

      <div className="shop-content content">
        <div><b>{shop.name}</b></div>
        <div>{shop.address}</div>
        {shop.phone_number && <div><i className="fa fa-phone"></i> <a href={`tel:${shop.phone_number}`}>{shop.phone_number}</a></div>}
        {shop.email && <div><i className="fa fa-envelope"></i> {shop.email}</div>}
      </div>
    </div>
  )
}

export default SaleBookingPage;
