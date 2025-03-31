"use strict";

import React, { useEffect, useState } from "react";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Line } from 'react-chartjs-2';

import { CommonServices } from "components/user_bot/api"
import I18n from 'i18n-js/index.js.erb';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);


const options = {
  responsive: true,
  plugins: {
    legend: {
      position: 'top',
    },
    title: {
      display: true,
    },
  },
  interaction: {
    intersect: false,
  },
};

const SalePagesVisitsMetric = ({demo, metric_path}) => {
  const [data, setData] = useState({
    labels: [],
    datasets: []
  })

  const fetchData = async () => {
    const [_error, response] = await CommonServices.get({
      url: metric_path,
      data: { demo }
    })

    setData(response.data)
  }

  useEffect(() => {
    fetchData()
  }, [])

  return (
    <div className="container margin-around">
      {
        data.datasets.length === 0 ? (
          <p className="margin-around centerize desc border border-solid border-gray-500 p-6">
            {I18n.t("user_bot.dashboards.metrics.no_data")}
          </p>
        ) : <Line options={options} data={data} />
      }
    </div>
  )
}

export default SalePagesVisitsMetric;
