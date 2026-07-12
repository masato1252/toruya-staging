import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

function copyUrl(url) {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(url);
  }
}

export default function SalesIndex({
  business_owner_id: businessOwnerId,
  draft_label: draftLabel,
}) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/sales`)
      .then((body) => {
        if (cancelled) return;
        setItems(body.data || []);
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
  }, [businessOwnerId]);

  if (loading) return <div className="booking-pages-list"><p>Loading...</p></div>;
  if (error) return <div className="booking-pages-list danger"><p>{error}</p></div>;

  return (
    <div className="booking-pages-list">
      {items.map((sale) => {
        const publicUrl = sale.public_url_path
          ? `${window.location.origin}${sale.public_url_path}`
          : null;
        return (
          <div className="field-row with-next-arrow" key={sale.id}>
            <a className="w-8-12" href={`/lines/user_bot/owner/${businessOwnerId}/sales/${sale.id}`}>
              <h3 className="text-gray-700 underline">
                <i className={`fa ${sale.is_booking_page ? "fa-calendar" : "fa-mobile-alt"}`} />
                {sale.draft ? `[${draftLabel || "下書き"}]` : ""}
                {sale.name}
              </h3>
              {sale.product_name ? <div className="desc">{sale.product_name}</div> : null}
              {sale.row_desc2 ? <div className="desc">{sale.row_desc2}</div> : null}
            </a>
            {publicUrl && (
              <div className="w-3-12 flex">
                <button
                  type="button"
                  className="btn btn-icon btn-tarco mr-2"
                  onClick={() => copyUrl(publicUrl)}
                >
                  <i className="far fa-clone" />
                </button>
                <a className="btn btn-icon btn-tarco" href={sale.public_url_path} target="_blank" rel="noreferrer">
                  <i className="fas fa-external-link-alt" />
                </a>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

SalesIndex.propTypes = {
  business_owner_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  draft_label: PropTypes.string,
};
