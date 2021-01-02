"use strict";

import React from "react";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import PriceBlock from "components/user_bot/sales/booking_pages/price_block";
import { Template } from "shared/builders"

const SaleBookingPage = ({shop, product, template, template_variables, content, staff, flow, demo, dispatch, jump}) => {
  return (
    <div className="sale-page centerize">
      <SaleTemplateContainer shop={shop} product={product}>
        {demo && (
          <span className="btn btn-yellow edit-mark" onClick={() => jump(1)}>
            <i className="fa fa-pencil-alt"></i>{I18n.t("action.edit")}
          </span>
        )}
        <Template
          template={template}
          {...template_variables}
          product_name={product.name}
        />

        <PriceBlock product={product} demo={demo} />
      </SaleTemplateContainer>

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
