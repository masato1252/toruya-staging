# frozen_string_literal: true

class CompanyInfoSerializer
  include JSONAPI::Serializer
  attribute :id, :email, :template_variables, :logo_url, :website

  attribute :type do |object|
    object.class.name
  end

  attribute :short_name do |object|
    case object
    when Shop
      object.short_name
    when Profile
      object.company_name
    end
  end

  attribute :name do |object|
    case object
    when Shop
      object.name
    when Profile
      object.company_name
    end
  end

  attribute :label do |object|
    case object
    when Shop
      object.display_name
    when Profile
      I18n.t("common.company_info")
    end
  end

  attribute :address do |object|
    if object.user.locale == :ja
      if object.company_full_address.present?
        "〒#{object.company_full_address}"
      end
    else
      object.company_full_address
    end
  end

  attribute :phone_number do |object|
    object.company_phone_number
  end

  attribute :holiday_working do |object|
    object.try(:holiday_working)
  end
end
