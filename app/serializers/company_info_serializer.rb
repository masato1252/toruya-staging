# frozen_string_literal: true

class CompanyInfoSerializer
  include JSONAPI::Serializer
  attribute :id, :email, :template_variables

  attribute :type do |object|
    object.class.name
  end

  attribute :logo_url do |object|
    case object
    when Shop
      ApplicationController.helpers.shop_logo_url(object, "260")
    when Profile
    end
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
      object.display_name
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
    case object
    when Shop
      "〒#{object.zip_code} #{object.address}" if object.address.present?
    when Profile
      object.company_full_address
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
end
