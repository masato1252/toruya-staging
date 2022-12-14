"use strict";

import React, { useEffect, useState } from "react";
import { CircularProgressbar, CircularProgressbarWithChildren } from 'react-circular-progressbar';

import { CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const ProgressCell = ({number}) => {
  return (
    <>
      <h4>{I18n.t("user_bot.dashboards.metrics.active_customers_rate")}</h4>
      <div className="w-6-12 mx-auto">
        <p>{I18n.t("user_bot.dashboards.metrics.last_year")}</p>
        <CircularProgressbarWithChildren className="progressbar" value={number * 100}>
          <div>
            <span className="text-4xl">{number * 100}</span>%
          </div>
        </CircularProgressbarWithChildren>
      </div>
    </>
  )
}

export default ProgressCell;
