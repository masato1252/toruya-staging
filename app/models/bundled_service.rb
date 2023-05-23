# == Schema Information
#
# Table name: bundled_services
#
#  id                        :bigint           not null, primary key
#  end_at                    :datetime
#  end_on_days               :integer
#  end_on_months             :integer
#  subscription              :boolean          default(FALSE)
#  bundler_online_service_id :integer          not null
#  online_service_id         :integer          not null
#
class BundledService < ApplicationRecord
  belongs_to :bundler_service, class_name: "OnlineService", foreign_key: :bundler_online_service_id
  belongs_to :online_service

  # forever and subscription no expire time
  def current_expire_time
    if end_at
      end_at
    elsif end_on_months
      Time.current.advance(months: end_on_months)
    elsif end_on_days
      Time.current.advance(days: end_on_days)
    end
  end

  def end_time
    if end_on_days
      {
        end_type: "end_on_days",
        end_on_days: end_on_days
      }
    elsif end_on_months
      {
        end_type: "end_on_months",
        end_on_months: end_on_months
      }
    elsif end_at
      {
        end_type: "end_at",
        end_time_date_part: end_at.to_fs(:date)
      }
    elsif subscription
      {
        end_type: "subscription"
      }
    else
      {
        end_type: "never"
      }
    end
  end

  def end_time_text
    if end_on_days
      I18n.t("sales.expire_after_n_days", days: end_on_days)
    elsif end_on_months
      I18n.t("sales.expire_after_n_months", months: end_on_months)
    elsif end_at
      I18n.l(end_at, format: :date_with_wday)
    elsif subscription
      I18n.t("sales.expire_by_subscription")
    else
      I18n.t("sales.never_expire")
    end
  end
end
