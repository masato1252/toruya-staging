"use strict";

import React, { useEffect, useState } from "react";
import { compatRead } from "../../../libraries/compat_api";
import I18n from "i18n-js/index.js.erb";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";
import { Line } from "react-chartjs-2";
import { CommonServices } from "components/user_bot/api";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

const options = {
  responsive: true,
  plugins: {
    legend: { position: "top" },
    title: { display: true },
  },
  interaction: { intersect: false },
};

const SalePagesVisitsMetric = ({ demo, metric_path, compatReadPath }) => {
  const [data, setData] = useState({ labels: [], datasets: [] });

  const fetchData = async () => {
    if (compatReadPath) {
      const suffix = demo ? `${compatReadPath.includes("?") ? "&" : "?"}demo=true` : "";
      const body = await compatRead(`${compatReadPath}${suffix}`);
      setData(body.data ?? { labels: [], datasets: [] });
      return;
    }

    const [_error, response] = await CommonServices.get({
      url: metric_path,
      data: { demo },
    });
    setData(response.data?.data ?? response.data);
  };

  useEffect(() => {
    fetchData();
  }, [compatReadPath, metric_path, demo]);

  return (
    <div className="container margin-around">
      {data.datasets.length === 0 ? (
        <p className="margin-around centerize desc border border-solid border-gray-500 p-6">
          {I18n.t("user_bot.dashboards.metrics.no_data")}
        </p>
      ) : (
        <Line options={options} data={data} />
      )}
    </div>
  );
};

export default SalePagesVisitsMetric;
