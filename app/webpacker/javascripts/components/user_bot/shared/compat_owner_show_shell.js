import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function copyToClipboard(text) {
  if (navigator.clipboard?.writeText) {
    return navigator.clipboard.writeText(text);
  }
  const el = document.createElement("textarea");
  el.value = text;
  document.body.appendChild(el);
  el.select();
  document.execCommand("copy");
  document.body.removeChild(el);
  return Promise.resolve();
}

function FieldRow({ row, label, warningLabels }) {
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
        ) : row.html ? (
          <span className="dotdotdot" dangerouslySetInnerHTML={{ __html: row.html }} />
        ) : (
          <span className="dotdotdot">{row.title}</span>
        )}
        {row.warnings?.map((code) => (
          <div key={code} className="danger warning">
            <i className="fas fa-exclamation-circle" /> {warningLabels?.[code] || code}
          </div>
        ))}
        {row.blocks?.map((block, i) => (
          <FieldRow key={`block-${i}`} row={block} warningLabels={warningLabels} />
        ))}
      </div>
    </>
  );
}

FieldRow.propTypes = {
  row: PropTypes.object.isRequired,
  label: PropTypes.string,
  warningLabels: PropTypes.object,
};

export default function CompatOwnerShowShell({
  pageContextPath,
  groupLabels,
  rowLabels,
  warningLabels,
  actionLabels,
  showQrForUrl,
}) {
  const [vm, setVm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [copied, setCopied] = useState(false);

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

  const labels = actionLabels || {};
  const loadingText = labels.loading || "Loading...";
  const deleteLabel = labels.delete || "Delete";
  const cloneLabel = labels.clone || "Clone";
  const copyLabel = labels.copy_url || "Copy URL";
  const confirmDelete = labels.confirm_delete || "Are you sure?";

  if (loading) return <p>{loadingText}</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!vm?.field_groups) return null;

  const publicUrl = vm.preview?.public_url;
  const absoluteUrl = publicUrl ? `${window.location.origin}${publicUrl}` : null;

  const handleCopy = () => {
    if (!absoluteUrl) return;
    copyToClipboard(absoluteUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

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
              warningLabels={warningLabels}
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

      {absoluteUrl && (
        <div className="margin-around">
          <input readOnly className="extend" value={absoluteUrl} onClick={(e) => e.target.select()} />
          <div className="centerize margin-around purchase-buttons">
            <button type="button" className="btn btn-tarco" onClick={handleCopy}>
              <i className="fas fa-copy" /> {copied ? (labels.copied || "Copied!") : copyLabel}
            </button>
            {publicUrl && (
              <a className="btn btn-tarco" href={publicUrl} target="_blank" rel="noreferrer">
                <i className="fas fa-external-link-alt" /> {labels.open || "Open"}
              </a>
            )}
          </div>
          {showQrForUrl && absoluteUrl && (
            <div className="centerize margin-around">
              <img
                src={`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encodeURIComponent(absoluteUrl)}`}
                alt="QR"
                width={150}
                height={150}
              />
            </div>
          )}
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
  warningLabels: PropTypes.object,
  actionLabels: PropTypes.object,
  showQrForUrl: PropTypes.bool,
};
