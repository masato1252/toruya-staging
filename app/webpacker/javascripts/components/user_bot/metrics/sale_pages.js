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
      text: 'Chart.js Line Chart',
    },
  },
  interaction: {
    intersect: false,
  },
};

const SalePagesMetric = ({demo}) => {
  const [data, setData] = useState({
    labels: [],
    datasets: []
  })

  const fetchData = async () => {
    const [_error, response] = await CommonServices.get({
      url: Routes.sale_pages_lines_user_bot_metrics_path({ format: "json" }),
      data: { demo }
    })

    setData(response.data)
  }

  useEffect(() => {
    fetchData()
  }, [])

  return (
    <Line options={options} data={data} />
  )
}

export default SalePagesMetric;
