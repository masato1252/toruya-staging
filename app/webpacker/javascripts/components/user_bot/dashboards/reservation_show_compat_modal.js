import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function formatDateTime(value) {
  const date = new Date(value);
  return {
    date: date.toLocaleDateString("ja-JP", {
      year: "numeric",
      month: "numeric",
      day: "numeric",
      weekday: "short",
    }),
    time: date.toLocaleTimeString("ja-JP", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }),
  };
}

export default function ReservationShowCompatModal({ pageContextPath, labels }) {
  const [modal, setModal] = useState(null);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (!cancelled) setModal(body?.data?.reservation_modal || null);
      })
      .catch((requestError) => {
        if (!cancelled) setError(requestError.message);
      });
    return () => {
      cancelled = true;
    };
  }, [pageContextPath]);

  const runAction = async (event, button) => {
    event.preventDefault();
    if (actionLoading || (button.confirm && !window.confirm(button.confirm))) return;

    setActionLoading(true);
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
      const response = await fetch(button.href, {
        method: button.method || "POST",
        headers: {
          Accept: "application/json",
          ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
        },
      });
      const body = await response.json().catch(() => null);
      if (!response.ok || body?.status === "failed") {
        throw new Error(body?.error_message || `状態更新に失敗しました (${response.status})`);
      }
      window.location.reload();
    } catch (actionError) {
      setError(actionError.message);
      setActionLoading(false);
    }
  };

  if (error) {
    return (
      <div className="modal-dialog toruya-modal" role="document">
        <div className="modal-content">
          <div className="modal-body danger">{error}</div>
        </div>
      </div>
    );
  }

  if (!modal) {
    return (
      <div className="modal-dialog toruya-modal" role="document">
        <div className="modal-content">
          <div className="modal-body">{labels.loading}</div>
        </div>
      </div>
    );
  }

  const start = formatDateTime(modal.start_at);
  const end = formatDateTime(modal.end_at);

  return (
    <div className="modal-dialog toruya-modal" role="document">
      <div className="modal-content">
        <div className="modal-header">
          <button type="button" className="close" data-dismiss="modal" aria-label={labels.close}>
            <span aria-hidden="true">&times;</span>
          </button>
          <h4 className="modal-title" id="reservation-show-modal">
            <span className={`reservation-state ${modal.state}`}>{modal.state_label}</span>
            <span>{start.date}</span>
            <span>{start.time}〜{end.time}</span>
          </h4>
        </div>

        <div className="modal-body">
          <div>
            {modal.customers.map((customer) => (
              <React.Fragment key={customer.id}>
                <i className={`fa fa-user customer-reservation-state ${customer.state_key}`} />
                <a href={customer.href} className="customer-link">{customer.name}</a>
              </React.Fragment>
            ))}
          </div>
          {modal.staff_names.length > 0 && (
            <div className="reservation-menu reservation-info-row">
              <i className="fa fa-tags" /><span>{modal.staff_names.join("、")}：{modal.menu_names.join("、")}</span>
            </div>
          )}
          {modal.with_warnings && (
            <div className="warning reservation-info-row">
              <i className="fa fa-check-circle" aria-hidden="true" />{labels.withWarnings}
            </div>
          )}
          {modal.memo && (
            <div className="reservation-info-row">
              <i className="fa fa-pencil" />{modal.memo}
            </div>
          )}
          {modal.meeting_url && (
            <div className="reservation-info-row">
              <i className="fa fa-video" /><a href={modal.meeting_url} target="_blank" rel="noreferrer">{modal.meeting_url}</a>
            </div>
          )}
        </div>

        <div className="modal-footer">
          <dl>
            {modal.state_buttons.filter((button) => button.key !== "book_next" && button.key !== "broadcast").map((button) => (
              <dd key={button.key}>
                <a
                  className={button.class_name}
                  href={button.href}
                  onClick={button.key === "details" ? undefined : (event) => runAction(event, button)}
                >
                  {actionLoading ? labels.loading : button.label}
                </a>
              </dd>
            ))}
          </dl>
        </div>
        <div className="modal-footer">
          <dl>
            {modal.state_buttons.filter((button) => button.key === "broadcast" || button.key === "book_next").map((button) => (
              <dd key={button.key}>
                <a className={button.class_name} href={button.href}>{button.label}</a>
              </dd>
            ))}
          </dl>
        </div>
      </div>
    </div>
  );
}

ReservationShowCompatModal.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  labels: PropTypes.shape({
    close: PropTypes.string.isRequired,
    loading: PropTypes.string.isRequired,
    withWarnings: PropTypes.string.isRequired,
  }).isRequired,
};
