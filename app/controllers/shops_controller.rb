# frozen_string_literal: true

class ShopsController < ActionController::Base
  skip_before_action :track_ahoy_visit
  layout "booking"

  def show
    @shop = Shop.find(params[:id])
    I18n.locale = @shop.user.social_user&.locale || I18n.default_locale
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end
end
