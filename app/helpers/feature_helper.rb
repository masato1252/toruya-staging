module FeatureHelper
  def support_feature_flags
    {
      support_phonetic_name: support_phonetic_name?,
      support_skip_required_shop_info: support_skip_required_shop_info?,
      support_tax_include_display: support_tax_include_display?
    }
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
end
