module FeatureHelper
  DATA_BY_LOCALE = {
    ja: {
      official_site_url: "https://toruya.com",
      line_developer_url: "https://developers.line.biz/ja/?openExternalBrowser=1"
    },
    tw: {
      official_site_url: "https://toruya.tw",
      line_developer_url: "https://developers.line.biz/zh-hant/?openExternalBrowser=1"
    }
  }

  def data_by_locale(data_name)
    DATA_BY_LOCALE[I18n.locale][data_name] || DATA_BY_LOCALE[:tw][data_name]
  end

  def support_feature_flags
    {
      support_phonetic_name: support_phonetic_name?,
      support_skip_required_shop_info: support_skip_required_shop_info?,
      support_tax_include_display: support_tax_include_display?,
      support_japanese_asset: support_japanese_asset?,
      support_faq_display: support_faq_display?,
      support_menu_restrict_order: support_menu_restrict_order?,
      support_terms_and_privacy_display: support_terms_and_privacy_display?,
      support_official_support_display: support_official_support_display?,
      support_booking_options_menu_concept: support_booking_options_menu_concept?
    }
  end

  def japanese_only?
    I18n.locale == :ja
  end

  alias_method :support_faq_display?, :japanese_only?
  alias_method :support_terms_and_privacy_display?, :japanese_only?
  alias_method :support_official_support_display?, :japanese_only?
  alias_method :support_menu_restrict_order?, :japanese_only?
  alias_method :support_tax_include_display?, :japanese_only?
  alias_method :support_japanese_asset?, :japanese_only?
  alias_method :support_phonetic_name?, :japanese_only?
  alias_method :support_stripe_payment?, :japanese_only?
  alias_method :support_square_payment?, :japanese_only?
  alias_method :support_character_filter?, :japanese_only?

  def support_skip_required_shop_info?
    I18n.locale != :ja
  end

  def support_booking_options_menu_concept?
    Current.business_owner&.booking_options_menu_concept
  end

  def money_sample(locale)
    case locale
    when :tw
      Money.new(1, :twd).format
    else
      "#{Money.new(1, :jpy).format(:ja_default_format)}(#{I18n.t("settings.booking_option.form.tax_include")})"
    end
  end
end
