import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function RowLink({ href, className, children, dataMethod, dataConfirm }) {
  if (!href) {
    return <div className={className}>{children}</div>;
  }
  return (
    <a href={href} className={className} data-method={dataMethod} data-confirm={dataConfirm}>
      {children}
      <i className="fa fa-angle-right" />
    </a>
  );
}

RowLink.propTypes = {
  href: PropTypes.string,
  className: PropTypes.string,
  children: PropTypes.node,
  dataMethod: PropTypes.string,
  dataConfirm: PropTypes.string,
};

function asDisplayText(value) {
  if (value == null) return null;
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  // Rails I18n sometimes returns nested hashes like { title: "..." }.
  if (typeof value === "object" && value.title != null) return String(value.title);
  return null;
}

function resolveRowTitle(row, valueLabels) {
  const rawTitle = asDisplayText(row?.title) ?? row?.title;
  if (!rawTitle || !row.header || !valueLabels?.[row.header]) return rawTitle;
  return valueLabels[row.header][rawTitle] ?? rawTitle;
}

function FieldRow({ row, label, warningLabels, valueLabels }) {
  const displayTitle = resolveRowTitle(row, valueLabels);
  const displayLabel = asDisplayText(label);
  const display = row.row_display || (row.row_class === "option-row" ? "option" : "inline");

  if (display === "option") {
    const descLines = (displayTitle || "").split("\n").filter(Boolean);
    return (
      <div className={`field-row option-row${row.href ? " with-next-arrow" : ""}`}>
        <div className="option-info">
          {row.href ? (
            <a href={row.href} className="break-line-content underline">
              {row.link_title || displayTitle}
            </a>
          ) : (
            <span className="break-line-content underline">{row.link_title || displayTitle}</span>
          )}
          {descLines.length ? (
            <div className="desc">
              {descLines.map((line, i) => (
                <React.Fragment key={i}>
                  {line}
                  {i < descLines.length - 1 ? <br /> : null}
                </React.Fragment>
              ))}
            </div>
          ) : null}
          {row.warnings?.map((code) => (
            <div key={code} className="warning">
              <i className="fas fa-exclamation-circle" /> {warningLabels?.[code] || code}
            </div>
          ))}
        </div>
        {row.blocks?.length ? (
          <div className="option-action">
            {row.blocks.map((block, i) =>
              block.href ? (
                <a
                  key={`block-${i}`}
                  href={block.href}
                  className="btn btn-orange"
                  data-method="delete"
                >
                  <i className="fa fa-minus" /> {asDisplayText(block.title) || block.title}
                </a>
              ) : null,
            )}
          </div>
        ) : null}
      </div>
    );
  }

  if (display === "split") {
    const closeClass = displayTitle === "CLOSE" ? "danger" : "";
    return (
      <RowLink href={row.href} className="field-row with-next-arrow with-format">
        <span>{row.link_title || displayLabel}</span>
        <span className={closeClass}>{displayTitle}</span>
      </RowLink>
    );
  }

  if (display === "header_link") {
    return (
      <RowLink href={row.href} className="field-row with-next-arrow with-format header-row">
        <span>{displayTitle}</span>
      </RowLink>
    );
  }

  if (display === "value" || display === "message") {
    const titleLines = (displayTitle || "").split("\n");
    return (
      <RowLink
        href={row.href}
        className={`field-row with-next-arrow with-format${row.row_class ? ` ${row.row_class}` : ""}`}
      >
        <span className="dotdotdot">
          {titleLines.map((line, i) => (
            <React.Fragment key={i}>
              {line}
              {i < titleLines.length - 1 ? <br /> : null}
            </React.Fragment>
          ))}
        </span>
        {row.warnings?.map((code) => (
          <div key={code} className="danger warning">
            <i className="fas fa-exclamation-circle" /> {warningLabels?.[code] || code}
          </div>
        ))}
      </RowLink>
    );
  }

  return (
    <RowLink
      href={row.href}
      className={`field-row with-next-arrow with-format${row.row_class ? ` ${row.row_class}` : ""}`}
    >
      <span>
        {displayLabel ? <span>{displayLabel}: </span> : null}
        <span className="text-gray-500">{displayTitle}</span>
      </span>
      {row.warnings?.map((code) => (
        <div key={code} className="danger warning">
          <i className="fas fa-exclamation-circle" /> {warningLabels?.[code] || code}
        </div>
      ))}
    </RowLink>
  );
}

FieldRow.propTypes = {
  row: PropTypes.object.isRequired,
  label: PropTypes.string,
  warningLabels: PropTypes.object,
  valueLabels: PropTypes.object,
};

function renderGroupRows(group, rowLabels, warningLabels, valueLabels) {
  const elements = [];
  let scheduleBuffer = [];

  const flushSchedule = () => {
    if (!scheduleBuffer.length) return;
    elements.push(
      <div key={`schedule-${elements.length}`} className="booking-page-business-schedules">
        {scheduleBuffer.map((row, idx) => (
          <FieldRow
            key={`schedule-${row.header}-${idx}`}
            row={row}
            label={rowLabels?.[row.header]}
            warningLabels={warningLabels}
            valueLabels={valueLabels}
          />
        ))}
      </div>,
    );
    scheduleBuffer = [];
  };

  group.rows.forEach((row, idx) => {
    if (row.row_display === "split") {
      scheduleBuffer.push(row);
      return;
    }
    flushSchedule();
    if (rowLabels?.[row.header] && (row.row_display === "value" || row.row_display === "message")) {
      elements.push(
        <div key={`${group.id}-header-${row.header}-${idx}`} className="field-header">
          {rowLabels[row.header]}
        </div>,
      );
    }
    elements.push(
      <FieldRow
        key={`${group.id}-${row.header}-${idx}`}
        row={row}
        label={rowLabels?.[row.header]}
        warningLabels={warningLabels}
        valueLabels={valueLabels}
      />,
    );
  });
  flushSchedule();
  return elements;
}

export default function CompatOwnerShowShell({
  pageContextPath,
  groupLabels,
  rowLabels,
  warningLabels,
  actionLabels,
  valueLabels,
  postProcessVm,
}) {
  const [vm, setVm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (cancelled) return;
        let data = body.data || null;
        if (data && typeof postProcessVm === "function") {
          data = postProcessVm(data);
        }
        setVm(data);
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
  }, [pageContextPath, postProcessVm]);

  const labels = actionLabels || {};
  const loadingText = labels.loading || "Loading...";
  const deleteLabel = labels.delete || "Delete";
  const cloneLabel = labels.clone || "Clone";
  const confirmDelete = labels.confirm_delete || "Are you sure?";

  if (loading) return <p>{loadingText}</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!vm?.field_groups) return null;

  const updatedAt = vm.updated_at
    ? new Date(vm.updated_at).toLocaleDateString("ja-JP", {
        year: "numeric",
        month: "long",
        day: "numeric",
        weekday: "short",
      })
    : null;

  return (
    <>
      {vm.field_groups.map((group) => (
        <React.Fragment key={group.id || group.label}>
          {groupLabels?.[group.label] ? (
            <div className="field-group-header" id={group.id || group.label}>
              {groupLabels[group.label]}
            </div>
          ) : null}
          {renderGroupRows(group, rowLabels, warningLabels, valueLabels)}
          {group.action_rows?.length ? (
            <div
              className={`action-block margin-around${
                group.id === "booking_options" && !group.rows?.length ? " border-red border-solid" : ""
              }`}
            >
              {group.action_rows.map((row, idx) =>
                row.header === "reorder" ? (
                  <a key={`action-${idx}`} className="btn btn-tarco" href={row.href}>
                    {row.title}
                  </a>
                ) : (
                  <a key={`action-${idx}`} className="btn btn-yellow" href={row.href}>
                    <i className="fa fa-plus" /> {row.title}
                  </a>
                ),
              )}
            </div>
          ) : null}
          {group.id === "booking_options" && !group.rows?.length && warningLabels?.no_booking_option ? (
            <div className="danger margin-around">
              <i className="fas fa-exclamation-circle" /> {warningLabels.no_booking_option}
            </div>
          ) : null}
        </React.Fragment>
      ))}

      {vm.actions?.refund_href && (
        <div className="action-block margin-around">
          <a className="btn btn-orange" href={vm.actions.refund_href}>
            {labels.refund || "クーリングオフ返金"}
          </a>
        </div>
      )}

      {vm.actions?.clone_href && (
        <div className="action-block margin-around">
          <a
            className="btn btn-yellow"
            href={vm.actions.clone_href}
            data-method={vm.actions.clone_method || "post"}
          >
            <i className="fa fa-copy" /> {cloneLabel}
          </a>
        </div>
      )}

      {vm.actions?.delete_href && (
        <div className="action-block margin-around">
          <a
            className="btn btn-orange"
            href={vm.actions.delete_href}
            data-method={vm.actions.delete_method || "delete"}
            data-confirm={confirmDelete}
          >
            <i className="fa fa-minus" /> {deleteLabel}
          </a>
        </div>
      )}

      {updatedAt && (
        <div className="margin-around text-center text-gray-500">
          {labels.updated_at_prefix || "更新日"} {updatedAt}
        </div>
      )}
    </>
  );
}

CompatOwnerShowShell.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  groupLabels: PropTypes.object,
  rowLabels: PropTypes.object,
  warningLabels: PropTypes.object,
  actionLabels: PropTypes.object,
  valueLabels: PropTypes.object,
  postProcessVm: PropTypes.func,
};
