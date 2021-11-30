"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js';
import Countdown from 'shared/countdown';
import { DemoEditButton } from 'shared/components';

import OnlineServiceSolution from "./solution"

const OnlineServicePage = ({company_info, name, solution_type, content_url, upsell_sale_page, demo, jump, light}) => {
  return (
    <div className="online-service-page">
      <div className="online-service-header">
        { company_info.logo_url ?  <img className="logo" src={company_info.logo_url} /> : <h2>{company_info.name}</h2> }
      </div>
      <div className="online-service-body centerize">
        <h2 className="name">
          {name}
          <DemoEditButton demo={demo} jump={() => jump(2)} />
        </h2>
        <div>
          <DemoEditButton demo={demo} jump={() => jump(1)} />
          <OnlineServiceSolution
            solution_type={solution_type}
            content_url={content_url}
            light={light}
          />
        </div>
      </div>
      {
        upsell_sale_page && (
          <div className="centerize">
            <h3 className="margin-around">
              {upsell_sale_page.label}
              <DemoEditButton demo={demo} jump={() => jump(5)} />
            </h3>
            {upsell_sale_page.end_at && (
              <div className="upsell">
                <p className="margin-around">
                  {I18n.t("online_service_page.special_price_time")}
                </p>
                <Countdown end_at={upsell_sale_page.end_at} />
              </div>
            )}

            {upsell_sale_page.slug && (
              <div className="margin-around">
                <a href={Routes.sale_page_url(upsell_sale_page?.slug)} className="btn btn-tarco btn-icon" target="_blank">
                  <i className="fa fa-credit-card"></i>{I18n.t("online_service_page.register_now")}
                </a>
              </div>
            )}
          </div>
        )
      }
    </div>
  )
}

export default OnlineServicePage;
