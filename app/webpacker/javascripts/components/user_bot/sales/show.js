import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function SaleShow({ businessOwnerId, saleId, labels }) {
  const [sale, setSale] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/sales/${saleId}/page_context`)
      .then((body) => {
        if (cancelled) return;
        setSale(body.data || null);
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
  }, [businessOwnerId, saleId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p className="danger">{error}</p>;
  if (!sale) return null;

  const base = `/lines/user_bot/owner/${businessOwnerId}/sales/${saleId}`;
  const priceText =
    sale.selling_price_cents != null
      ? `¥${Number(sale.selling_price_cents).toLocaleString("ja-JP")}`
      : labels.noPrice;

  return (
    <>
      <div className="field-group-header">{labels.about}</div>
      <a className="field-row" href={`${base}/edit?attribute=internal_name`}>
        <span>{labels.internalName}: {sale.name}</span>
      </a>
      <div className="field-row">
        <span>{labels.slug}: {sale.slug || "—"}</span>
      </div>
      <div className="field-row">
        <span>
          {labels.privacy}: {sale.draft ? labels.draft : labels.published}
        </span>
      </div>
      <div className="field-row">
        <span>{labels.price}: {priceText}</span>
      </div>
      {sale.public_url_path && (
        <a className="field-row" href={sale.public_url_path} target="_blank" rel="noreferrer">
          <span>{labels.publicUrl}</span>
        </a>
      )}
    </>
  );
}

SaleShow.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  saleId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  labels: PropTypes.object.isRequired,
};
