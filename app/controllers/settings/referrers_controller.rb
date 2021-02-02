# frozen_string_literal: true

class Settings::ReferrersController < SettingsController
  def index
    @referrals = current_user.referrals.includes(:referrer)
    # {
    #   user_id => charge date,
    # }
    # {
    #   2 => "2019/11/20",
    #   64 => "2019/12/17",
    #   65 => "2019/12/18"
    # }
    @charges_by_user_id = SubscriptionCharge.completed.
      where(user_id: @referrals.pluck(:referrer_id)).
      select('DISTINCT ON ("user_id") *').
      order(:user_id, id: :desc).
      each_with_object({}) { |charge, h| h[charge.user_id] = I18n.l(charge.created_at.to_date) }
  end

  def copy_modal
    render layout: false
  end
end
