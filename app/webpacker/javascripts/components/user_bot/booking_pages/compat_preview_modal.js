import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import BookingPagePreview from "user_bot/bookings/booking_page_preview";
import { compatRead } from "../../../libraries/compat_api";

function copyToClipboard(text) {
  if (navigator.clipboard?.writeText) return navigator.clipboard.writeText(text);

  const input = document.createElement("textarea");
  input.value = text;
  document.body.appendChild(input);
  input.select();
  document.execCommand("copy");
  document.body.removeChild(input);
  return Promise.resolve();
}

function shareButtonCode(url, label) {
  const style = [
    "display: inline-block",
    "background-color: #aecfc8",
    "border: 1px solid #84b3aa",
    "border-radius: 6px",
    "line-height: 40px",
    "color: #fff",
    "font-size: 14px",
    "font-weight: bold",
    "text-decoration: none",
    "padding: 0 10px",
  ].join("; ");
  return `<a href="${url}" style="${style}" target="_blank">${label}</a>`;
}

export default function CompatPreviewModal({ pageContextPath, labels }) {
  const [preview, setPreview] = useState(null);
  const [error, setError] = useState(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (!cancelled) setPreview(body.data?.preview || null);
      })
      .catch((requestError) => {
        if (!cancelled) setError(requestError.message);
      });
    return () => {
      cancelled = true;
    };
  }, [pageContextPath]);

  const publicUrl = preview?.public_url ? `${window.location.origin}${preview.public_url}` : null;
  const copy = (value) => {
    copyToClipboard(value).then(() => {
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <div className="modal-dialog booking-preview-modal" role="document">
      <div className="modal-content">
        <div className="modal-header">
          <button type="button" className="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          <h4 className="modal-title">{labels.title}</h4>
        </div>
        <div>
          {error ? <p className="danger margin-around">{error}</p> : null}
          {preview?.props ? (
            <>
              <BookingPagePreview
                shop={preview.props.shop}
                booking_page={preview.props.booking_page}
                booking_option={preview.props.booking_option}
                i18n={labels}
              />
              {preview.props.other_options_count > 0 ? (
                <div className="others-options">
                  その他{preview.props.other_options_count}価格
                </div>
              ) : null}
            </>
          ) : null}
        </div>
        {publicUrl ? (
          <div className="modal-footer centerize">
            <div>
              <input type="text" value={publicUrl} readOnly className="extend" onClick={(e) => e.target.select()} />
            </div>
            <button type="button" className="btn btn-tarco" onClick={() => copy(publicUrl)}>
              {copied ? labels.copied : labels.copy_url}
            </button>
            <button
              type="button"
              className="btn btn-tarco"
              onClick={() => copy(shareButtonCode(publicUrl, labels.share_button))}
            >
              {copied ? labels.copied : labels.copy_code}
            </button>
          </div>
        ) : null}
      </div>
    </div>
  );
}

CompatPreviewModal.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  labels: PropTypes.object.isRequired,
};
