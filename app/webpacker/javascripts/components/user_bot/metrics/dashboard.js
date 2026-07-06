import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function Trend({ value }) {
  if (value > 0) return <span className="text-success">+{value}</span>;
  if (value < 0) return <span className="text-danger">{value}</span>;
  return <span>0</span>;
}

export default function MetricsDashboard({
  businessOwnerId,
  startDate,
  endDate,
  labels,
}) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams();
    if (startDate) params.set("start_date", startDate);
    if (endDate) params.set("end_date", endDate);
    const suffix = params.toString() ? `?${params.toString()}` : "";

    compatRead(`/lines/user_bot/owner/${businessOwnerId}/metrics/dashboard${suffix}`)
      .then((body) => {
        if (cancelled) return;
        setData(body.data || {});
      })
      .catch((err) => {
        if (!cancelled) setError(err.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => { cancelled = true; };
  }, [businessOwnerId, startDate, endDate]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!data) return null;

  const days = data.days_in_period ?? 30;

  return (
    <div className="row">
      <div className="col-sm-3 col-xs-6 p-0 flex justify-center centerize">
        <div className="p-4 w-11-12 metric-cell h-full">
          <h5>{labels.activeCustomersRate}</h5>
          <p>{labels.lastYear}</p>
          <span className="text-4xl">{data.active_customers_rate ?? 0}</span>%
        </div>
      </div>
      <div className="col-sm-3 col-xs-6 p-0 flex justify-center centerize">
        <div className="p-4 w-11-12 metric-cell h-full">
          <h5>{labels.newCustomers}</h5>
          <p>{labels.lastNDays.replace(":days", String(days))}</p>
          <span className="text-4xl">{data.customers_count ?? 0}</span>
          <Trend value={data.comparison_customers_count ?? 0} />
        </div>
      </div>
      <div className="col-sm-3 col-xs-6 p-0 flex justify-center centerize mt-4 mt-sm-0">
        <div className="p-4 w-11-12 metric-cell h-full">
          <h5>{labels.newReservations}</h5>
          <p>{labels.lastNDays.replace(":days", String(days))}</p>
          <span className="text-4xl">{data.reservations_count ?? 0}</span>
          <Trend value={data.comparison_reservations_count ?? 0} />
        </div>
      </div>
      <div className="col-sm-3 col-xs-6 p-0 flex justify-center centerize mt-4 mt-sm-0">
        <div className="p-4 w-11-12 metric-cell h-full">
          <h5>{labels.totalRevenue}</h5>
          <p>{labels.lastNDays.replace(":days", String(days))}</p>
          <span className="text-4xl">{data.customers_payment ?? 0}</span>
          <Trend value={data.comparison_customers_payment ?? 0} />
        </div>
      </div>
    </div>
  );
}

MetricsDashboard.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  startDate: PropTypes.string,
  endDate: PropTypes.string,
  labels: PropTypes.object.isRequired,
};
