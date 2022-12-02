"use strict";

import React, { useEffect, useState } from "react";
import { CircularProgressbar, CircularProgressbarWithChildren } from 'react-circular-progressbar';
import 'react-circular-progressbar/dist/styles.css';

import { CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const ProgressCell = ({number}) => {
  return (
    <div class="col-sm-3 centerize">
      <div class="p-6 metric-cell">
        <h4>{I18n.t("user_bot.dashboards.metrics.active_customers_rate")}</h4>
        <div>
          <p>{I18n.t("user_bot.dashboards.metrics.last_year")}</p>
          <CircularProgressbarWithChildren className="progressbar" value={number * 100}>
            <div>
              <span className="text-6xl">{number * 100}</span>%
            </div>
          </CircularProgressbarWithChildren>
        </div>
      </div>
    </div>
  )
}

export default ProgressCell;
