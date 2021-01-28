"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import Countdown from 'shared/countdown';
import { DemoEditButton } from 'shared/components';

import OnlineServiceSolution from "./solution";

const OnlineServicePage = ({company_info, name, solution, content, upsell_sale_page, demo, jump}) => {
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
            solution={solution}
            content={content}
            light={true}
          />
        </div>
        <h3 className="margin-around">
          {upsell_sale_page?.label}
          {upsell_sale_page && <DemoEditButton demo={demo} jump={() => jump(5)} />}
        </h3>
        {upsell_sale_page?.end_at && (
          <div className="upsell">
            <p className="margin-around">
              {I18n.t("online_service_page.special_price_time")}
            </p>
            <Countdown end_at={upsell_sale_page.end_at} />
          </div>
        )}
      </div>
    </div>
  )
}

export default OnlineServicePage;
