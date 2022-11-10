"use strict";

import React, { useEffect, useState } from "react";
import { CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const SalePagesConversionsMetric = ({demo}) => {
  const [data, setData] = useState([])

  const fetchData = async () => {
    const [_error, response] = await CommonServices.get({
      url: Routes.sale_pages_conversions_lines_user_bot_metrics_path({format: "json"}),
      data: { demo }
    })

    setData(response.data)
  }

  useEffect(() => {
    fetchData()
  }, [])

  return (
    <div className="container margin-around table">
      <h2>Weekly Sale page conversion rate</h2>
      <div className="row">
        <div className="col-sm-3">{I18n.t("user_bot.dashboards.metrics.sale_page")}</div>
        <div className="col-sm-1">{I18n.t("user_bot.dashboards.metrics.visit_count")}</div>
        <div className="col-sm-1">{I18n.t("user_bot.dashboards.metrics.purchased_count")}</div>
        <div className="col-sm-1">{I18n.t("user_bot.dashboards.metrics.conversion_rate")}</div>
      </div>
      {
        data.length === 0 ? (
          <p className="margin-around centerize desc border border-solid border-gray-500 p-6">
            No Data yet
          </p>
        ) : (
          <>
            {data.map((sale_page_data) => (
              <div className="row" key={sale_page_data.label}>
                <div className="col-sm-3">{sale_page_data.label}</div>
                <div className="col-sm-1">{sale_page_data.visit_count}</div>
                <div className="col-sm-1">{sale_page_data.purchased_count}</div>
                <div className="col-sm-1">{sale_page_data.format_rate}</div>
              </div>
            ))}
          </>
        )
      }
    </div>
  )
}

export default SalePagesConversionsMetric;
