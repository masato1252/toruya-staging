module ProductLocale
  extend ActiveSupport::Concern
  included do
    before_action :set_locale
  end

  def product_social_user
    raise "implement this method in controller"
  end

  def set_locale
    I18n.locale = params[:locale].presence || product_social_user&.locale || cookies[:locale] || I18n.default_locale
    cookies.clear_across_domains(:locale)
    cookies.set_across_domains(:locale, I18n.locale, expires: 20.years.from_now)
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end
end