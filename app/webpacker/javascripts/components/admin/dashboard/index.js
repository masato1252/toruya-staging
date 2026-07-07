import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function ApplicationList({ title, items, allHref }) {
  return (
    <>
      <h1>
        {title} {allHref ? <a href={allHref}>All</a> : null}
      </h1>
      <ul>
        {items.map((item) => (
          <li key={item.id}>
            {item.user_name} {item.user_email} {new Date(item.updated_at).toLocaleString()}
            {item.state === "pending" ? (
              <>
                {" "}
                <a href={item.approve_href} className="btn btn-success" data-method="post">
                  Approve
                </a>{" "}
                <a href={item.reject_href} className="btn btn-danger" data-method="post" data-confirm="Are you sure?">
                  Reject
                </a>
              </>
            ) : null}
          </li>
        ))}
      </ul>
    </>
  );
}

ApplicationList.propTypes = {
  title: PropTypes.string.isRequired,
  items: PropTypes.array.isRequired,
  allHref: PropTypes.string,
};

function WithdrawalList({ title, items }) {
  return (
    <>
      <h1>{title}</h1>
      <ul>
        {items.map((item) => (
          <li key={item.id}>
            {item.receiver_name} {item.receiver_email} {new Date(item.created_at).toLocaleDateString()}{" "}
            {item.amount_cents} {item.amount_currency}{" "}
            <a href={item.mark_paid_href} className="btn btn-success" data-method="post">
              Paid
            </a>{" "}
            <a href={item.receipt_href} target="_blank" rel="noreferrer">
              Receipt
            </a>
          </li>
        ))}
      </ul>
    </>
  );
}

WithdrawalList.propTypes = {
  title: PropTypes.string.isRequired,
  items: PropTypes.array.isRequired,
};

export default function AdminDashboardIndex({ applicationsTitle, withdrawalsTitle, allApplicationsHref }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead("/admin/dashboard")
      .then((body) => {
        if (cancelled) return;
        setData(body.data || null);
      })
      .catch((err) => {
        if (!cancelled) setError(err.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;

  return (
    <>
      <ApplicationList
        title={applicationsTitle}
        items={data?.pending_applications || []}
        allHref={allApplicationsHref}
      />
      <br />
      <hr />
      <br />
      <WithdrawalList title={withdrawalsTitle} items={data?.pending_withdrawals || []} />
    </>
  );
}

AdminDashboardIndex.propTypes = {
  applicationsTitle: PropTypes.string.isRequired,
  withdrawalsTitle: PropTypes.string.isRequired,
  allApplicationsHref: PropTypes.string.isRequired,
};
