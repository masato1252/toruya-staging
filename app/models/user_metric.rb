# == Schema Information
#
# Table name: user_metrics
#
#  id      :bigint           not null, primary key
#  content :json
#  user_id :bigint
#
# Indexes
#
#  index_user_metrics_on_user_id  (user_id)
#
class UserMetric < ApplicationRecord
  store_accessor :content, %i[
    any_booking_page_visit_ever_over_criteria
    any_booking_page_page_view_and_conversion_rate_ever_over_criteria
  ]
end
