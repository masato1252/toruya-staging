import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";
import SaleBookingPage from "user_bot/sales/booking_pages";
import SaleOnlineService from "user_bot/sales/online_services";
import BookingPagePreview from "user_bot/bookings/booking_page_preview";
import SaleDemoPage from "user_bot/sales/demo";
import CoursePage from "user_bot/services/online_service_page/course";
import OnlineServicePage from "user_bot/services/online_service_page";

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

export default function CompatOwnerShowPreview({
  pageContextPath,
  supportFeatureFlags,
  mobilePreviewLabel,
  previewLabels,
  shareButtonText,
}) {
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

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

  if (loading) return null;

  // Shop demo preview has no public URL; still render the phone mock.
  if (!preview) return null;
  if (!preview.public_url && preview.react_component !== "sales_demo") return null;

  const { public_url: publicUrl, react_component: reactComponent, props } = preview;
  const absoluteUrl = publicUrl ? `${window.location.origin}${publicUrl}` : "";
  const labels = previewLabels || {};

  const previewNode = (() => {
    if (!reactComponent || !props) return null;
    if (reactComponent === "online_services") {
      return <SaleOnlineService {...props} support_feature_flags={supportFeatureFlags} />;
    }
    if (reactComponent === "booking_pages") {
      return <SaleBookingPage {...props} support_feature_flags={supportFeatureFlags} />;
    }
    if (reactComponent === "booking_page_preview") {
      return (
        <BookingPagePreview
          shop={props.shop}
          booking_page={props.booking_page}
          booking_option={props.booking_option}
          i18n={labels}
        />
      );
    }
    if (reactComponent === "sales_demo") {
      return <SaleDemoPage shop={props.shop} />;
    }
    if (reactComponent === "online_service_course") {
      return (
        <CoursePage
          course={props.course}
          lesson_ids={props.lesson_ids || []}
          preview={props.preview !== false}
          lesson_id={props.lesson_id}
        />
      );
    }
    if (reactComponent === "online_service_page") {
      return <OnlineServicePage {...props} />;
    }
    return null;
  })();

  const handleCopyUrl = () => {
    if (!absoluteUrl) return;
    copyToClipboard(absoluteUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <>
      {absoluteUrl ? (
        <>
          <input
            readOnly
            className="extend"
            value={absoluteUrl}
            onClick={(e) => e.target.select()}
          />
          <div className="centerize margin-around purchase-buttons">
            <button type="button" className="btn btn-tarco" onClick={handleCopyUrl}>
              <i className="fas fa-copy" /> {copied ? labels.copied || "コピーしました" : shareButtonText || labels.copy_button || "予約ボタンをコピー"}
            </button>
          </div>
          <div className="centerize margin-around">
            <img
              src={`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encodeURIComponent(absoluteUrl)}`}
              alt="QR"
              width={150}
              height={150}
            />
          </div>
        </>
      ) : null}
      {previewNode ? (
        <div className="fake-mobile-layout hidden-xs">
          {previewNode}
          {props?.other_options_count > 0 ? (
            <div className="others-options">
              {labels.other_options || `その他${props.other_options_count}価格`}
            </div>
          ) : null}
        </div>
      ) : null}
      {previewNode && mobilePreviewLabel ? (
        <div className="centerize margin-around hidden-xs">
          <span className="text-gray-500">{mobilePreviewLabel}</span>
        </div>
      ) : null}
    </>
  );
}

CompatOwnerShowPreview.propTypes = {
  pageContextPath: PropTypes.string.isRequired,
  supportFeatureFlags: PropTypes.object,
  mobilePreviewLabel: PropTypes.string,
  previewLabels: PropTypes.object,
  shareButtonText: PropTypes.string,
};
