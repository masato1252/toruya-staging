"use strict";

import React, { useEffect, useState } from "react";
import { CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';

const SalePagesConversionsMetric = ({}) => {
  const [data, setData] = useState([])

  const fetchData = async () => {
    const [_error, response] = await CommonServices.get({
      url: Routes.sale_pages_conversions_lines_user_bot_metrics_path({format: "json"})
    })

    setData(response.data)
  }

  useEffect(() => {
    fetchData()
  }, [])

  return (
    <div class="container">
      <div class="row">
        <div class="col-sm-3">Sale Page</div>
        <div class="col-sm-1">Visit</div>
        <div class="col-sm-1">Sign up</div>
        <div class="col-sm-1">Conversion</div>
      </div>
      {data.map((sale_page_data) => (
        <div class="row">
          <div class="col-sm-3">{sale_page_data.label}</div>
          <div class="col-sm-1">{sale_page_data.visit_count}</div>
          <div class="col-sm-1">{sale_page_data.purchased_count}</div>
          <div class="col-sm-1">{sale_page_data.format_rate}</div>
        </div>
      ))}
    </div>
  )
}

export default SalePagesConversionsMetric;
