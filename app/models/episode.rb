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

  belongs_to :online_service
  belongs_to :user

  scope :ended_yet, -> { where("end_at is NULL or :now < end_at", now: Time.current) }
  scope :started, -> { where("start_at is NULL or :now > start_at", now: Time.current) }
  scope :available, -> { started.ended_yet }

  def start_time
    if start_at
      {
        start_type: "start_at",
        start_time_date_part: start_at.to_fs(:date)
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
      I18n.t("common.right_away_after_purchased")
    end
  end

  def end_time
    if end_at
      {
        end_type: "end_at",
        end_time_date_part: end_at.to_fs(:date)
      }
    else
      {
        end_type: "never"
      }
    end
  end

  def end_time_text
    if end_at
      I18n.l(end_at, format: :date_with_wday)
    else
      I18n.t("sales.never_expire")
    end
  end

  def started?
    return true unless start_at # start right away servce
    return Time.current >= start_at
  end

  def ended?
    return false unless end_at # start right away servce
    return Time.current >= end_at
  end

  def available?
    started? && !ended?
  end

  def state
    return "available" if available?
    "inactive"
  end

  def message_template_variables(customer_or_user)
    online_service.message_template_variables(customer_or_user).merge!(
      {
        customer_name: customer_or_user.name,
        episode_name: name,
        episode_end_date: end_time_text
      }
    )
  end
end
