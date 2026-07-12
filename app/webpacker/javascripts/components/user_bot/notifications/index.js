import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function NotificationSection({ title, items, empty }) {
  if (!items?.length) return null;
  return (
    <>
      <div className="field-header">{title}</div>
      <div className="booking-pages-list">
        {items.map((item) => (
          <a key={item.id} className="field-row with-next-arrow" href={item.href}>
            <div>
              <h3>
                {item.customer_name || item.title}
                {item.company_name || item.shop_name ? (
                  <span className="border p-1 border-solid border-gray-500 text-gray-500 text-10px ml-2">
                    {item.company_name || item.shop_name}
                  </span>
                ) : null}
              </h3>
              {item.preview || item.customers || item.goal_type ? (
                <div className="desc dotdotdot">{item.preview || item.customers || item.goal_type}</div>
              ) : null}
            </div>
            <i className="fa fa-angle-right" />
          </a>
        ))}
      </div>
    </>
  );
}

NotificationSection.propTypes = {
  title: PropTypes.string.isRequired,
  items: PropTypes.array,
  empty: PropTypes.bool,
};

export default function NotificationsIndex({ businessOwnerId, schedulesPath, labels }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/notifications`)
      .then((body) => {
        if (cancelled) return;
        const payload = body.data || {};
        setData(payload);
        if (!payload.has_notifications && schedulesPath) {
          window.location.href = schedulesPath;
        }
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
  }, [businessOwnerId, schedulesPath]);

  if (loading) return <p>処理中...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!data?.has_notifications) return null;

  return (
    <div>
      <NotificationSection
        title={labels.unreadMessages}
        items={data.unread_messages}
      />
      <NotificationSection
        title={labels.pendingReservations}
        items={data.pending_reservations}
      />
      <NotificationSection
        title={labels.pendingCustomerServices || "承認待ちサービス"}
        items={data.pending_customer_services}
      />
    </div>
  );
}

NotificationsIndex.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  schedulesPath: PropTypes.string,
  labels: PropTypes.object.isRequired,
};
