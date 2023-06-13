# frozen_string_literal: true

class CustomerOptionSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower

  attribute :id, :memo, :address, :birthday
  attribute :user_id, :contact_group_id, :rank_id, :last_name, :first_name,
    :phonetic_last_name, :phonetic_first_name, :custom_id, :updated_at, :reminder_permission,
    :phone_numbers_details, :emails_details, :address_details, :rank, :simple_address
  attribute :label, &:name
  attribute :value, &:id

  attribute :groupName do |c|
    c.contact_group&.name
  end

  attribute :updatedByUserName do |c|
    c.updated_by_user&.name || ""
  end

  attribute :lastUpdatedAt do |c|
    c.updated_at ? I18n.l(c.updated_at.to_date, format: :year_month_date) : ""
  end

  attribute :socialUserId do |c|
    c.social_customer&.social_user_id
  end

  attribute :socialUserName do |c|
    c.social_customer&.social_user_name.presence || I18n.t("common.no_connection")
  end
end
