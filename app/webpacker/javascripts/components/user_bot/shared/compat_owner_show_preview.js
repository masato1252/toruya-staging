import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";
import SaleBookingPage from "user_bot/sales/booking_pages";
import SaleOnlineService from "user_bot/sales/online_services";

export default function CompatOwnerShowPreview({ pageContextPath, supportFeatureFlags, mobilePreviewLabel }) {
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showMobile, setShowMobile] = useState(false);

  useEffect(() => {
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (cancelled) return;
        setPreview(body.data?.preview ?? null);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [pageContextPath]);

  if (loading || !preview) return null;

  const { public_url: publicUrl, react_component: reactComponent, props } = preview;
  const absoluteUrl = publicUrl ? `${window.location.origin}${publicUrl}` : null;

  const previewNode =
    reactComponent && props ? (
      reactComponent === "online_services" ? (
        <SaleOnlineService {...props} support_feature_flags={supportFeatureFlags} />
      ) : (
        <SaleBookingPage {...props} support_feature_flags={supportFeatureFlags} />
      )
    ) : null;

  return (
    <>
      {absoluteUrl && (
        <>
          <input readOnly className="extend" value={absoluteUrl} onClick={(e) => e.target.select()} />
          <div className="centerize margin-around purchase-buttons">
            <a className="btn btn-tarco" href={publicUrl} target="_blank" rel="noreferrer">
              <i className="fas fa-external-link-alt" /> Open
            </a>
            {previewNode && (
              <button type="button" className="btn btn-tarco" onClick={() => setShowMobile(true)}>
                <i className="fas fa-mobile-alt" /> {mobilePreviewLabel || "Mobile preview"}
              </button>
            )}
          </div>
        </>
      )}
      {previewNode && !showMobile && (
        <div className="fake-mobile-layout hidden-xs">{previewNode}</div>
      )}
      {previewNode && showMobile && (
        <div className="modal-overlay" onClick={() => setShowMobile(false)} role="presentation">
          <div className="fake-mobile-layout margin-around" onClick={(e) => e.stopPropagation()} role="dialog">
            {previewNode}
          </div>
        </div>
      )}
    </>
  );
}

CompatOwnerShowPreview.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  supportFeatureFlags: PropTypes.object,
  mobilePreviewLabel: PropTypes.string,
};
