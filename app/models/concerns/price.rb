module Price
  extend ActiveSupport::Concern

  def price_text
    return if amount.blank?

    if amount.currency.iso_code == "JPY"
      tax_type = I18n.t("settings.booking_option.form.#{tax_include ? "tax_include" : "tax_excluded"}")

      if amount.zero?
        "#{amount.format(:ja_default_format)}"
      else
        "#{amount.format(:ja_default_format)}(#{tax_type})"
      end
    else
      amount.format
    end
  end
end
