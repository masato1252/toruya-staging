# frozen_string_literal: true

class ReferralsController < ActionController::Base
  layout "home"

  def show
    @user = User.find_by!(referral_token: params[:token])
  end
end
