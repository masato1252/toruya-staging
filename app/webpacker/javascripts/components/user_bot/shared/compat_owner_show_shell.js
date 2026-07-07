import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function FieldRow({ row, label }) {
  const header = label || row.header;

  return (
    <>
      {header && <div className="field-header">{header}</div>}
      <div className={`field-row${row.row_class ? ` ${row.row_class}` : ""}${row.href ? " with-next-arrow" : ""}`}>
        {row.href ? (
          <a href={row.href} className="w-full block">
            <span className="dotdotdot">{row.link_title || row.title}</span>
            {row.title && row.link_title && row.title !== row.link_title && (
              <div className="desc">{row.title}</div>
            )}
          </a>
        ) : (
          <span className="dotdotdot">{row.title}</span>
        )}
        {row.warnings?.map((code) => (
          <div key={code} className="danger warning">
            <i className="fas fa-exclamation-circle" /> {code}
          </div>
        ))}
      </div>
    </>
  );
}

export default function CompatOwnerShowShell({ pageContextPath, groupLabels, rowLabels }) {
  const [vm, setVm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

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

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!vm?.field_groups) return null;

  return (
    <>
      {vm.field_groups.map((group) => (
        <React.Fragment key={group.id || group.label}>
          {groupLabels?.[group.label] && (
            <div className="field-group-header">{groupLabels[group.label]}</div>
          )}
          {group.rows.map((row, idx) => (
            <FieldRow
              key={`${group.id}-${row.header}-${idx}`}
              row={row}
              label={rowLabels?.[row.header]}
            />
          ))}
          {group.action_rows?.map((row, idx) => (
            <div key={`action-${idx}`} className="action-block margin-around">
              <a className="btn btn-yellow" href={row.href}>
                <i className="fa fa-plus" /> {row.title}
              </a>
            </div>
          ))}
        </React.Fragment>
      ))}

      {vm.actions?.delete_href && (
        <div className="action-block margin-around">
          <a
            className="btn btn-orange"
            href={vm.actions.delete_href}
            data-method={vm.actions.delete_method || "delete"}
            data-confirm="Are you sure?"
          >
            <i className="fa fa-minus" /> Delete
          </a>
        </div>
      )}

      {vm.updated_at && (
        <div className="margin-around text-center text-gray-500">
          {new Date(vm.updated_at).toLocaleDateString()}
        </div>
      )}
    </>
  );
}

CompatOwnerShowShell.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  groupLabels: PropTypes.object,
  rowLabels: PropTypes.object,
};
