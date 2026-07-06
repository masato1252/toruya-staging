import React, { useEffect, useMemo, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../../libraries/compat_api";
import ReservationForm from "./reservation_form";

function defaultDatePart() {
  return new Date().toISOString().slice(0, 10);
}

function defaultTimePart() {
  const d = new Date();
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

export default function ReservationFormShell({ businessOwnerId, shopId, shellProps }) {
  const [formProps, setFormProps] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const searchParams = useMemo(() => new URLSearchParams(window.location.search), []);

  useEffect(() => {
    let cancelled = false;
    compatRead(
      `/lines/user_bot/owner/${businessOwnerId}/shops/${shopId}/reservations/form_context`,
    )
      .then((body) => {
        if (cancelled) return;
        const ctx = body.data || {};
        const startDate = searchParams.get("start_time_date_part") || defaultDatePart();
        const startTime = searchParams.get("start_time_time_part") || defaultTimePart();

        setFormProps({
          ...shellProps,
          reservation_properties: {
            ...shellProps.reservation_properties,
            menu_group_options: ctx.menu_group_options || [],
            staff_options: ctx.staff_options || [],
            reservation_staff_states:
              ctx.reservation_staff_states || shellProps.reservation_properties?.reservation_staff_states,
            is_editable: true,
          },
          reservation_form: {
            ...shellProps.reservation_form,
            shop: ctx.shop || shellProps.reservation_form?.shop,
            start_time_date_part: startDate,
            start_time_time_part: startTime,
            end_time_date_part: startDate,
            end_time_time_part: startTime,
            menu_staffs_list: shellProps.reservation_form?.menu_staffs_list?.length
              ? shellProps.reservation_form.menu_staffs_list
              : [
                  {
                    menu: null,
                    position: 0,
                    menu_id: "",
                    menu_required_time: "",
                    menu_interval_time: "",
                    staff_ids: [],
                    menu_online: "",
                  },
                ],
          },
        });
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
  }, [businessOwnerId, shopId, shellProps, searchParams]);

  if (loading) return <p className="margin-around centerize">Loading...</p>;
  if (error) return <p className="danger margin-around">{error}</p>;
  if (!formProps) return null;

  return <ReservationForm props={formProps} />;
}

ReservationFormShell.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  shopId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  shellProps: PropTypes.object.isRequired,
};
