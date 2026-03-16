# frozen_string_literal: true

class CompanyInfoSerializer
  include JSONAPI::Serializer
  attribute :id, :email, :template_variables, :logo_url, :website

  attribute :email do |object|
    case object
    when Shop
      object.email
    when Profile
      object.company_email
    end
  end

  attribute :logo_url do |object|
    object.logo_url
  end

  attribute :type do |object|
    object.class.name
  end

  attribute :short_name do |object|
    case object
    when Shop
      object.read_attribute(:name)
    when Profile
      object.company_name
    end
  end

  attribute :name do |object|
    case object
    when Shop
      object.read_attribute(:name)
    when Profile
      object.company_name
    end
  end

  attribute :label do |object|
    I18n.t("common.company_info")
  end

  attribute :address do |object|
    address = case object
    when Shop
      object.company_full_address
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
      object.phone_number
    when Profile
      object.company_phone_number
    end
  end

  attribute :holiday_working do |object|
    object.try(:holiday_working)
  end
end
