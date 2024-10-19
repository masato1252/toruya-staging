module ProductLocale
  extend ActiveSupport::Concern
  included do
    before_action :set_locale
  end

  def product_social_user
    raise "implement this method in controller"
  end

  def set_locale
    I18n.locale = params[:locale].presence || product_social_user&.locale || I18n.default_locale
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end
end