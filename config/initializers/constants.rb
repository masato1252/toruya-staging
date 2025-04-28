# frozen_string_literal: true

START_AT_DATE_PART = "start_at_date_part"
START_AT_TIME_PART = "start_at_time_part"
END_AT_DATE_PART = "end_at_date_part"
END_AT_TIME_PART = "end_at_time_part"
INTEGER_MAX = 4611686018427387903

TOURS_VIDEOS = {
  line_settings_required_for_online_service: "_s2DmD6T7wE",
  line_settings_required_for_booking_page: "_s2DmD6T7wE"
}

# https://stripe.com/docs/api/refunds/object?lang=ruby#refund_object-status
STRIPE_REFUND_STATUS = {
  succeeded: "succeeded"
}

# https://stripe.com/docs/api/subscriptions/object#subscription_object-status
STRIPE_SUBSCRIPTION_STATUS = {
  canceled: "canceled",
  active: "active"
}

STRIPE_DESCRIPTION_LIMIT = 20

FROM = {
  service_customer_show: "service_customer_show",
  survey_response_show: "survey_response_show"
}

LOCALE_TIME_ZONE = {
  ja: "Asia/Tokyo",
  tw: "Asia/Taipei",
  tl: "Asia/Bangkok"
}