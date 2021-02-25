"use strict";

import React from "react";
import SaleTemplateView from "components/user_bot/sales/online_services/sale_template_view";
import PriceBlock from "components/user_bot/sales/online_services/price_block";
import I18n from 'i18n-js/index.js.erb';

const SaleOnlineService = ({product, social_account_add_friend_url, template, template_variables, content, staff, demo, dispatch, jump,
  price, normal_price, quantity, introduction_video, is_started, is_ended, purchase_url}) => {
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
        is_started={is_started}
        is_ended={is_ended}
        purchase_url={purchase_url}
      />

      <div className="product-content content">
        {demo && (
          <span className="btn btn-yellow edit-mark" onClick={() => jump(9)}>
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
          <span className="btn btn-yellow edit-mark" onClick={() => jump(10)}>
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
