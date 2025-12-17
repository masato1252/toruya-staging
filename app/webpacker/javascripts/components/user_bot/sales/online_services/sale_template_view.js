"use strict";

import React from "react";
import SaleTemplateContainer from "components/user_bot/sales/booking_pages/sale_template_container";
import PriceBlock from "components/user_bot/sales/online_services/price_block";
import { DemoEditButton } from 'shared/components';
import { Template } from "shared/builders"
import I18n from 'i18n-js/index.js.erb';

import OnlineServiceSolution from "components/user_bot/services/online_service_page/solution";

const SaleTemplateView = ({
  company_info,
  product,
  demo,
  template,
  template_variables,
  social_account_add_friend_url,
  jump,
  no_action,
  price,
  normal_price,
  quantity,
  introduction_video_url,
  is_started,
  start_at,
  end_at,
  start_time,
  end_time,
  is_ended,
  purchase_url,
  payable,
  is_external,
  support_feature_flags
}) => (
  <SaleTemplateContainer shop={company_info} product={product}>
    {demo && (
      <span className="btn btn-yellow edit-mark" onClick={() => jump(5)}>
        <i className="fa fa-pencil-alt"></i>{I18n.t("action.edit")}
      </span>
    )}
    <Template
      template={template}
      {...template_variables}
      product_name={product.product_name}
    />

    {introduction_video_url && (
      <div>
        <DemoEditButton demo={demo} jump={() => jump(8)} />
        <OnlineServiceSolution
          solution_type="video"
          content_url={introduction_video_url}
          light={false}
        />
      </div>
    )}

    <div>
      <DemoEditButton demo={demo} jump={() => jump(1)} />
      <PriceBlock
        solution_type={product.solution_type}
        demo={demo}
        no_action={no_action}
        social_account_add_friend_url={social_account_add_friend_url}
        price={price}
        normal_price={normal_price?.price_amount}
        quantity={quantity}
        start_at={start_at}
        end_at={end_at}
        start_time={start_time}
        end_time={end_time}
        is_started={is_started}
        is_ended={is_ended}
        purchase_url={purchase_url}
        payable={payable}
        is_external={is_external}
        support_feature_flags={support_feature_flags}
      />
    </div>
  </SaleTemplateContainer>
)

export default SaleTemplateView;
