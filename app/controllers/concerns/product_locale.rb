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
    cookies[:locale] = { value: I18n.locale, domain: :all }
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end
end