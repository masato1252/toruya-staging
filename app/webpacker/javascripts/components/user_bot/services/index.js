import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";

export default function ServicesIndex({
  business_owner_id: businessOwnerId,
  new_sale_for_service_path: newSaleForServicePath,
  goal_type_labels: goalTypeLabels,
  no_sale_page_warning: noSalePageWarning,
  draft_sale_page_warning: draftSalePageWarning,
  no_content_warning: noContentWarning,
  continue_editing_label: continueEditingLabel,
}) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    compatRead(`/lines/user_bot/owner/${businessOwnerId}/services`)
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
    return () => { cancelled = true; };
  }, [businessOwnerId]);

  if (loading) return <div className="booking-pages-list"><p>Loading...</p></div>;
  if (error) return <div className="booking-pages-list danger"><p>{error}</p></div>;

  return (
    <div className="booking-pages-list">
      {items.map((service) => (
        <div className="field-row with-next-arrow" key={service.id}>
          <div>
            <a href={`/lines/user_bot/owner/${businessOwnerId}/services/${service.id}`}>
              <h3 className="underline text-gray-700">{service.display_name}</h3>
              <div className="desc">{goalTypeLabels[service.goal_type] || service.goal_type}</div>
            </a>
            {service.missing_sale_page && (
              <div className="warning">
                <small><i className="fas fa-exclamation-triangle" /> {noSalePageWarning}</small>
                {newSaleForServicePath && service.slug && (
                  <a className="btn btn-yellow btn-save btn-tweak" href={`${newSaleForServicePath}?slug=${service.slug}`}>
                    <i className="fas fa-plus" />
                  </a>
                )}
              </div>
            )}
            {service.draft_sale_pages?.length > 0 && (
              <div className="warning">
                <small><i className="fas fa-exclamation-triangle" /> {draftSalePageWarning}</small>
                {service.draft_sale_pages.map((page) => (
                  <a key={page.id} className="btn btn-yellow btn-save btn-tweak" href={`/sale_pages/${page.slug}`}>
                    {continueEditingLabel || "続けて編集"}
                  </a>
                ))}
              </div>
            )}
            {service.missing_chapters && (
              <div className="warning">
                <small><i className="fas fa-exclamation-triangle" /> {noContentWarning}</small>
                <a className="btn btn-yellow btn-save btn-tweak" href={`/lines/user_bot/owner/${businessOwnerId}/services/${service.id}/chapters`}>
                  <i className="fas fa-plus" />
                </a>
              </div>
            )}
          </div>
          <i className="fa fa-angle-right" />
        </div>
      ))}
    </div>
  );
}

ServicesIndex.propTypes = {
  business_owner_id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  new_sale_for_service_path: PropTypes.string,
  goal_type_labels: PropTypes.object.isRequired,
  no_sale_page_warning: PropTypes.string.isRequired,
  draft_sale_page_warning: PropTypes.string.isRequired,
  no_content_warning: PropTypes.string.isRequired,
  continue_editing_label: PropTypes.string,
};
