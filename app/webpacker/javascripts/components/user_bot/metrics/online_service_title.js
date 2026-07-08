import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import I18n from "i18n-js/index.js.erb";
import { compatRead } from "../../../libraries/compat_api";

export default function OnlineServiceTitle({ businessOwnerId, serviceId }) {
  const [serviceName, setServiceName] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/services`)
      .then((body) => {
        if (cancelled) return;
        const service = (body.data || []).find((row) => String(row.id) === String(serviceId));
        setServiceName(service?.display_name || service?.internal_name || service?.name || "");
      })
      .catch(() => {
        if (!cancelled) setServiceName("");
      });
    return () => {
      cancelled = true;
    };
  }, [businessOwnerId, serviceId]);

  if (!serviceName) {
    return <h2>{I18n.t("common.processing")}</h2>;
  }

  return (
    <h2>
      {I18n.t("user_bot.dashboards.metrics.weekly_service_sale_page_visit_count", {
        service_name: serviceName,
      })}
    </h2>
  );
}

OnlineServiceTitle.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  serviceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
};
