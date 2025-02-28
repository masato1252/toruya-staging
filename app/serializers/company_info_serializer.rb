# frozen_string_literal: true

class CompanyInfoSerializer
  include JSONAPI::Serializer
  attribute :id, :email, :template_variables, :logo_url, :website

  attribute :email do |object|
    if object.class == Shop
      object.user.profile.company_email
    else
      object.company_email
    end
  end

  attribute :logo_url do |object|
    if object.class == Shop
      object.user.profile.logo_url
    else
      object.logo_url
    end
  end

  attribute :type do |object|
    object.class.name
  end

  attribute :short_name do |object|
    case object
    when Shop
      object.user.profile.company_name
    when Profile
      object.company_name
    end
  end

  attribute :name do |object|
    case object
    when Shop
      object.user.profile.company_name
    when Profile
      object.company_name
    end
  end

  attribute :label do |object|
    case object
    when Shop
      I18n.t("common.company_info")
    when Profile
      I18n.t("common.company_info")
    end
  end

  attribute :address do |object|
    address = case object
    when Shop
      object.user.profile.company_full_address
    when Profile
      object.company_full_address
    end

    if object.user.locale == :ja
      if address.present?
        "〒#{address}"
      end
    else
      address
    end
  end

  attribute :phone_number do |object|
    case object
    when Shop
      object.user.profile.company_phone_number
    when Profile
      object.company_phone_number
    end
  end

  attribute :holiday_working do |object|
    object.try(:holiday_working)
  end
end
