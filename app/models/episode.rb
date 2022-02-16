# == Schema Information
#
# Table name: episodes
#
#  id                :bigint           not null, primary key
#  content_url       :string           not null
#  end_at            :datetime
#  name              :string           not null
#  note              :text
#  solution_type     :string           not null
#  start_at          :datetime
#  tags              :string           default([]), is an Array
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  online_service_id :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_episodes_on_online_service_id  (online_service_id)
#
class Episode < ApplicationRecord
  include ContentHelper

  def start_time
    if start_at
      {
        start_type: "start_at",
        start_time_date_part: start_at.to_s(:date)
      }
    else
      {
        start_type: "now"
      }
    end
  end

  def start_time_text
    if start_at
      I18n.l(start_at, format: :date_with_wday)
    else
      I18n.t("sales.sale_now")
    end
  end
end
