module FeatureHelper
  def support_feature_flags
    {
      support_phonetic_name: support_phonetic_name?,
      support_skip_required_shop_info: support_skip_required_shop_info?,
      support_tax_include_display: support_tax_include_display?,
      support_japanese_asset: support_japanese_asset?,
      support_toruya_message_reply: support_toruya_message_reply?,
      support_faq_display: support_faq_display?
    }
  end

  def support_faq_display?
    I18n.locale == :ja
  end

  def support_phonetic_name?
    I18n.locale == :ja
  end

  def support_skip_required_shop_info?
    I18n.locale != :ja
  end

  def support_tax_include_display?
    I18n.locale == :ja
  end

  def support_japanese_asset?
    I18n.locale == :ja
  end

  def support_toruya_message_reply?
    !!Current.business_owner&.toruya_message_reply
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
