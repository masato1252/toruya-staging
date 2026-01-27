# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  
  prepend_before_action :verify_user, only: [:destroy]

  # newアクションだけ"booking"レイアウトを使用
  before_action :set_booking_layout, only: [:new]
  before_action :clear_oauth_session, only: [:new]
  
  def new
    super
  end
  
  def clear_oauth_session
    # OAuth関連のSessionをクリア（店舗固有のLINE Login情報が誤って使われないように）
    session.delete(:line_oauth_credentials)
    session.delete(:oauth_social_account_id)
    session.delete(:line_oauth_who)
    session.delete(:oauth_redirect_to_url)
    %w[booking_option_ids booking_date booking_at staff_id customer_id].each do |key|
      session.delete("oauth_#{key}")
    end
  end
  
  private
  
  def set_booking_layout
    self.class.layout "booking"
  end
  
  # This method intercepts SessionsController#destroy action
  # When user sign out and sign in another tab, and sign in again that casue its session is different.
  # http://stackoverflow.com/q/22487290/609365
  def verify_user
    redirect_to root_path unless verified_request?
  end
end
