"use strict";

import React from "react";
import SaleTemplateView from "components/user_bot/sales/booking_pages/sale_template_view";
import PriceBlock from "components/user_bot/sales/booking_pages/price_block";
import I18n from 'i18n-js/index.js.erb';

const SaleBookingPage = (
  {product, social_account_add_friend_url, template, template_variables, content, staff, demo, dispatch, jump,
  shop, flow}) => {
  return (
    <div className="sale-page centerize">
      <SaleTemplateView
        shop={shop}
        product={product}
        demo={demo}
        template={template}
        template_variables={template_variables}
        social_account_add_friend_url={social_account_add_friend_url}
        jump={jump}
      />

      <div className="product-content content">
        {demo && (
          <span className="btn btn-yellow edit-mark" onClick={() => jump(4)}>
            <i className="fa fa-pencil-alt"></i>
            {I18n.t("action.edit")}
          </span>
        )}
        <h3 className="header centerize">
          {content.desc1}
        </h3>
        <img className="product-picture" src={content.picture_url} />
        <p>
          {content.desc2}
        </p>
      </div>

      <div className="staff-content content">
        {demo && (
          <span className="btn btn-yellow edit-mark" onClick={() => jump(5)}>
            <i className="fa fa-pencil-alt"></i>
            {I18n.t("action.edit")}
          </span>
        )}
        <img className="staff-picture" src={staff.picture_url} />
        <b className="name">{staff.name}</b>
        <p>
          {staff.introduction}
        </p>
      </div>

      <div className="flow-content content">
        {demo && (
          <span className="btn btn-yellow edit-mark" onClick={() => jump(6)}>
            <i className="fa fa-pencil-alt"></i>
            {I18n.t("action.edit")}
          </span>
        )}
        <h3 className="header centerize">
          {I18n.t("user_bot.dashboards.sales.booking_page_creation.flow_header")}
        </h3>
        {flow.map((flowStep, index) => {
          return (
            <div className="flow-step" key={`flow-step-${index}`}>
              <div className="number-step-header">
                <div className="number-step">{index + 1}</div>
              </div>
              <p>
                {flowStep}
              </p>
            </div>
          )
        })}
      </div>

      <div className="apply-content content">
        <h3 className="header centerize">{I18n.t("common.apply_now")}</h3>

        <PriceBlock product={product} demo={demo} />
      </div>

      <div className="shop-content content">
        <div><b>{shop.name}</b></div>
        <div>{shop.address}</div>
        <div><i className="fa fa-phone"></i> <a href={`tel:${shop.phone_number}`}>{shop.phone_number}</a></div>
        <div><i className="fa fa-envelope"></i> {shop.email}</div>
      </div>
    </div>
  )
}

export default SaleBookingPage;
