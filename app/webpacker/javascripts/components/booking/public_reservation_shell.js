import React, { useEffect, useMemo, useState } from "react";
import PropTypes from "prop-types";
import { compatRead } from "../../libraries/compat_api";
import BookingReservationFormFunction from "./booking_reservation_form_function";

function applyMetaTags(meta) {
  if (!meta) return;
  if (meta.title) document.title = meta.title;
  const setMeta = (name, content) => {
    if (!content) return;
    let el = document.querySelector(`meta[name="${name}"]`);
    if (!el) {
      el = document.createElement("meta");
      el.setAttribute("name", name);
      document.head.appendChild(el);
    }
    el.setAttribute("content", content);
  };
  const setOg = (property, content) => {
    if (!content) return;
    let el = document.querySelector(`meta[property="${property}"]`);
    if (!el) {
      el = document.createElement("meta");
      el.setAttribute("property", property);
      document.head.appendChild(el);
    }
    el.setAttribute("content", content);
  };
  setMeta("description", meta.description);
  setOg("og:title", meta.og_title || meta.title);
  setOg("og:description", meta.description);
  if (meta.og_url_path) {
    setOg("og:url", `${window.location.origin}${meta.og_url_path}`);
  }
  if (meta.og_image) setOg("og:image", meta.og_image);
}

function parseBookingOptionIds(searchParams, isSingleOption, fallbackOptions) {
  const raw = searchParams.get("booking_option_ids");
  if (raw) return raw.split(",").map((id) => parseInt(id, 10)).filter(Boolean);
  const single = searchParams.get("booking_option_id");
  if (single) return [parseInt(single, 10)].filter(Boolean);
  if (isSingleOption && fallbackOptions?.length === 1) return [fallbackOptions[0].id];
  return [];
}

function buildFormProps(shellProps, body, searchParams) {
  const page = body.data || {};
  const includes = body.includes || {};
  const bookingPageOptions = includes.booking_page_options || [];
  const isSingleOption = includes.is_single_booking_option;
  const bookingOptionIds = parseBookingOptionIds(searchParams, isSingleOption, bookingPageOptions);
  const staffMap = includes.staff_booking_options_map || { any_staff: bookingPageOptions };
  const availableStaffs = includes.available_staffs || [];
  const staffSelectionRequired = includes.staff_selection_required;
  const staffIdParam = searchParams.get("staff_id");
  const selectedStaffId =
    staffIdParam != null
      ? parseInt(staffIdParam, 10)
      : availableStaffs.length === 1
        ? availableStaffs[0].id
        : null;
  const staffKey = selectedStaffId != null ? String(selectedStaffId) : null;
  const bookingOptions =
    staffKey && staffMap[staffKey] ? staffMap[staffKey] : staffMap.any_staff || bookingPageOptions;

  const bookingPage = {
    ...shellProps.booking_page,
    title: page.title ?? shellProps.booking_page?.title,
    greeting: page.greeting ?? shellProps.booking_page?.greeting,
    note: page.note ?? shellProps.booking_page?.note,
    online_payment_enabled: page.online_payment_enabled,
    multiple_selection: page.multiple_selection,
    payment_option: page.payment_option,
    is_single_option: isSingleOption,
    is_started: page.is_started ?? shellProps.booking_page?.is_started,
    is_ended: page.is_ended ?? shellProps.booking_page?.is_ended,
    is_customer_address_required:
      page.is_customer_address_required ?? shellProps.booking_page?.is_customer_address_required,
    shop_logo_url: includes.shop_logo_url ?? shellProps.booking_page?.shop_logo_url,
    shop_name: includes.shop?.short_name ?? includes.shop?.name ?? shellProps.booking_page?.shop_name,
  };

  const calendar = {
    ...shellProps.calendar,
    selectedDate: includes.default_selected_date || shellProps.calendar?.selectedDate,
  };

  return {
    ...shellProps,
    booking_page: bookingPage,
    calendar,
    business_owner_id: page.user_id ?? shellProps.business_owner_id,
    booking_options_quota: includes.booking_options_quota ?? shellProps.booking_options_quota ?? {},
    product_requirement: includes.product_requirement ?? shellProps.product_requirement ?? null,
    booking_reservation_form: {
      ...shellProps.booking_reservation_form,
      booking_option_ids: bookingOptionIds,
      booking_option_selected_flow_done: bookingOptionIds.length > 0,
      booking_date: searchParams.get("booking_date") || shellProps.booking_reservation_form?.booking_date,
      booking_at: searchParams.get("booking_at") || shellProps.booking_reservation_form?.booking_at,
      available_staffs: availableStaffs,
      staff_selection_required: staffSelectionRequired,
      selected_staff_id: selectedStaffId,
      staff_booking_options_map: staffMap,
      booking_options: bookingOptions,
      user_id: page.user_id ?? shellProps.booking_reservation_form?.user_id,
    },
  };
}

export default function PublicReservationShell({ slug, shellProps, customerId }) {
  const [formProps, setFormProps] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const searchParams = useMemo(() => new URLSearchParams(window.location.search), []);

  useEffect(() => {
    let cancelled = false;
    const query = customerId ? `?customer_id=${customerId}` : "";
    compatRead(`/booking/${slug}/page_context${query}`)
      .then((body) => {
        if (cancelled) return;
        if (!body?.data) {
          setError("Booking page not found.");
          return;
        }
        applyMetaTags(body.includes?.meta);
        setFormProps(buildFormProps(shellProps, body, searchParams));
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
  }, [slug, shellProps, searchParams, customerId]);

  if (loading) return <p className="margin-around centerize">Loading...</p>;
  if (error) return <p className="danger margin-around">{error}</p>;
  if (!formProps) return null;

  return <BookingReservationFormFunction props={formProps} />;
}

PublicReservationShell.propTypes = {
  slug: PropTypes.string.isRequired,
  shellProps: PropTypes.object.isRequired,
  customerId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
