import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import I18n from "i18n-js/index.js.erb";
import { compatRead } from "../../../../libraries/compat_api";

function ScheduleRow({ href, label, title }) {
  const closeClass = title === "CLOSE" ? "danger" : "";
  return (
    <a href={href} className="field-row with-next-arrow with-format">
      <span>{label}</span>
      <span className={closeClass}>
        {title}
        <i className="fa fa-angle-right" />
      </span>
    </a>
  );
}

ScheduleRow.propTypes = {
  href: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
};

export default function BusinessSchedulesIndexShell({ pageContextPath }) {
  const [vm, setVm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const dayNames = I18n.t("date.day_names");

  useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (cancelled) return;
        setVm(body.data || null);
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
  }, [pageContextPath]);

  if (loading) return <p>{I18n.t("common.processing")}</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!vm?.field_groups) return null;

  const baseGroup = vm.field_groups.find((group) => group.id === "base_business_time");
  const holidayGroup = vm.field_groups.find((group) => group.id === "holiday");

  return (
    <>
      <div className="field-header">
        {I18n.t("user_bot.dashboards.settings.business_schedules.base_business_time")}
      </div>
      {baseGroup?.rows?.map((row) => {
        const wday = Number(String(row.header || "").replace("wday_", ""));
        return (
          <ScheduleRow
            key={row.header}
            href={row.href}
            label={dayNames[wday % 7]}
            title={row.title || "CLOSE"}
          />
        );
      })}

      <div className="field-header">
        {I18n.t("user_bot.dashboards.settings.business_schedules.holiday_label")}
      </div>
      {holidayGroup?.rows?.map((row) => (
        <ScheduleRow
          key={row.header}
          href={row.href}
          label={I18n.t("user_bot.dashboards.settings.business_schedules.national_holiday_label")}
          title={row.title || "CLOSE"}
        />
      ))}

      <div className="margin-around centerize">
        <div className="break-line-content">
          {I18n.t("user_bot.dashboards.settings.business_schedules.business_time_introduction1")}
        </div>
        <br />
        <div className="break-line-content">
          {I18n.t("user_bot.dashboards.settings.business_schedules.business_time_introduction2")}
        </div>
      </div>
    </>
  );
}

BusinessSchedulesIndexShell.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
};
