# frozen_string_literal: true

class ReferralsController < ActionController::Base
  skip_before_action :track_ahoy_visit
  layout "home"

  def show
    @user = User.find_by!(referral_token: params[:token])
  end
end
