"use strict";

import React from "react";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import PriceBlock from "components/user_bot/sales/booking_pages/price_block";
import { Template } from "shared/builders"
import I18n from 'i18n-js/index.js.erb';

const SaleTemplateView = ({shop, product, demo, template, template_variables, social_account_add_friend_url, jump, no_action}) => (
  <SaleTemplateContainer shop={shop} product={product}>
    {demo && (
      <span className="btn btn-yellow edit-mark" onClick={() => jump(1)}>
        <i className="fa fa-pencil-alt"></i>{I18n.t("action.edit")}
      </span>
    )}
    <Template
      template={template}
      {...template_variables}
      product_name={product.product_name}
    />

    <PriceBlock
      product={product}
      demo={demo}
      no_action={no_action}
      social_account_add_friend_url={social_account_add_friend_url}
    />
  </SaleTemplateContainer>
)

export default SaleTemplateView;
