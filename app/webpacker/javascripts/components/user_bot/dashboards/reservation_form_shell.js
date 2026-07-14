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

export default function ReservationFormShell({
  businessOwnerId,
  shopId,
  reservationId,
  initialForm,
  shellProps,
}) {
  const [formProps, setFormProps] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const searchParams = useMemo(() => new URLSearchParams(window.location.search), []);

  useEffect(() => {
    let cancelled = false;
    const resolvedReservationId =
      reservationId || searchParams.get("id") || searchParams.get("reservation_id");
    const query = new URLSearchParams();
    if (resolvedReservationId) query.set("reservation_id", resolvedReservationId);
    if (searchParams.get("customer_id")) query.set("customer_id", searchParams.get("customer_id"));

    compatRead(
      `/lines/user_bot/owner/${businessOwnerId}/shops/${shopId}/reservations/form_context${
        query.toString() ? `?${query}` : ""
      }`,
    )
      .then((body) => {
        if (cancelled) return;
        const ctx = body.data || {};
        const reservation = ctx.reservation || {};
        const hydratedReservation = { ...reservation, ...(initialForm || {}) };
        const isEdit = Boolean(resolvedReservationId && reservation.id);
        const initialCustomers = initialForm?.customers_list || [];
        const customers = [...initialCustomers, ...(ctx.customers_list || [])].filter(
          (customer, index, list) =>
            list.findIndex(
              (candidate) =>
                String(candidate.customer_id || candidate.value) ===
                String(customer.customer_id || customer.value),
            ) === index,
        );

        const startDate =
          hydratedReservation.start_time_date_part ||
          searchParams.get("start_time_date_part") ||
          defaultDatePart();
        const startTime =
          hydratedReservation.start_time_time_part ||
          searchParams.get("start_time_time_part") ||
          defaultTimePart();
        const endDate = hydratedReservation.end_time_date_part || startDate;
        const endTime = hydratedReservation.end_time_time_part || startTime;

        const defaultMenuRow = {
          menu: null,
          position: 0,
          menu_id: "",
          menu_required_time: "",
          menu_interval_time: "",
          staff_ids: [{ staff_id: "" }],
          menu_online: "",
        };

        setFormProps({
          ...shellProps,
          reservation_properties: {
            ...shellProps.reservation_properties,
            menu_group_options: ctx.menu_group_options || [],
            staff_options: ctx.staff_options || [],
            reservation_staff_states:
              ctx.reservation_staff_states || shellProps.reservation_properties?.reservation_staff_states,
            existing_staff_states: ctx.staff_states || [],
            is_editable: shellProps.reservation_properties?.is_editable ?? true,
          },
          reservation_form: {
            ...shellProps.reservation_form,
            shop: ctx.shop || shellProps.reservation_form?.shop,
            id: hydratedReservation.id ?? shellProps.reservation_form?.id,
            reservation_id:
              hydratedReservation.reservation_id ?? hydratedReservation.id ?? null,
            memo: hydratedReservation.memo ?? shellProps.reservation_form?.memo,
            meeting_url:
              hydratedReservation.meeting_url ?? shellProps.reservation_form?.meeting_url,
            by_staff_id:
              hydratedReservation.by_staff_id ?? shellProps.reservation_form?.by_staff_id,
            start_time_date_part: startDate,
            start_time_time_part: startTime,
            end_time_date_part: endDate,
            end_time_time_part: endTime,
            menu_staffs_list:
              initialForm?.menu_staffs_list?.length
                ? initialForm.menu_staffs_list
                : isEdit && ctx.menu_staffs_list?.length
                ? ctx.menu_staffs_list
                : shellProps.reservation_form?.menu_staffs_list?.length
                  ? shellProps.reservation_form.menu_staffs_list
                  : [defaultMenuRow],
            staff_states:
              initialForm?.staff_states?.length
                ? initialForm.staff_states
                : ctx.staff_states || shellProps.reservation_form?.staff_states || [],
            customers_list:
              customers.length > 0
                ? customers
                : shellProps.reservation_form?.customers_list || [],
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
  }, [businessOwnerId, shopId, reservationId, initialForm, shellProps, searchParams]);

  if (loading) return <p className="margin-around centerize">Loading...</p>;
  if (error) return <p className="danger margin-around">{error}</p>;
  if (!formProps) return null;

  return <ReservationForm props={formProps} />;
}

ReservationFormShell.propTypes = {
  businessOwnerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  shopId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  reservationId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  initialForm: PropTypes.object,
  shellProps: PropTypes.object.isRequired,
};
