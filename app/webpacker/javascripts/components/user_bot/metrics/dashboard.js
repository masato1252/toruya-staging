import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function Trend({ value }) {
  if (value > 0) return <span className="text-success">+{value}</span>;
  if (value < 0) return <span className="text-danger">{value}</span>;
  return <span>0</span>;
}

function formatYen(cents) {
  if (cents == null) return "—";
  return `¥${Number(cents).toLocaleString("ja-JP")}`;
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

  const [revenueRows, setRevenueRows] = useState([]);

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

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams();
    if (startDate) params.set("start_date", startDate);
    if (endDate) params.set("end_date", endDate);
    const suffix = params.toString() ? `?${params.toString()}` : "";

    compatRead(`/lines/user_bot/owner/${businessOwnerId}/metrics/booking_revenue${suffix}`)
      .then((body) => {
        if (cancelled) return;
        setRevenueRows(body.data || []);
      })
      .catch(() => {});

    return () => { cancelled = true; };
  }, [businessOwnerId, startDate, endDate]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!data) return null;

  const days = data.days_in_period ?? 30;
  const osRanking = data.services_mapping_total_amount || [];

  return (
  <>
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

    {osRanking.length > 0 && (
      <div className="row mt-4">
        <div className="col-xs-12">
          <h5>{labels.onlineServicesRevenue || "Online services revenue"}</h5>
          <table className="table">
            <thead>
              <tr>
                <th>{labels.serviceName || "Service"}</th>
                <th>{labels.totalRevenue || "Revenue"}</th>
              </tr>
            </thead>
            <tbody>
              {osRanking.map((row) => (
                <tr key={row.name}>
                  <td>{row.name}</td>
                  <td>{formatYen(row.total_amount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    )}

    {revenueRows.length > 0 && (
      <div className="row mt-4">
        <div className="col-xs-12">
          <h5>{labels.bookingPagesRevenue || "Booking revenue by option"}</h5>
          <table className="table">
            <thead>
              <tr>
                <th>{labels.optionName || "Option"}</th>
                <th>{labels.reservationCount || "Count"}</th>
                <th>{labels.totalRevenue || "Revenue"}</th>
              </tr>
            </thead>
            <tbody>
              {revenueRows.map((row) => (
                <tr key={row.booking_option_id}>
                  <td>{row.booking_option_name || row.name}</td>
                  <td>{row.reservation_count ?? row.count}</td>
                  <td>{formatYen(row.revenue_cents ?? row.revenue)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    )}
  </>
  );
}

MetricsDashboard.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  startDate: PropTypes.string,
  endDate: PropTypes.string,
  labels: PropTypes.object.isRequired,
};
