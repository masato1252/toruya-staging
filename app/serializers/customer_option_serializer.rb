# frozen_string_literal: true

class CustomerOptionSerializer
  include JSONAPI::Serializer

  attribute :id, :memo, :address, :birthday
  attribute :userId, &:user_id
  attribute :contactGroupId, &:contact_group_id
  attribute :rankId, &:rank_id
  attribute :lastName, &:last_name
  attribute :firstName, &:first_name
  attribute :phoneticLastName, &:phonetic_last_name
  attribute :phoneticFirstName, &:phonetic_first_name
  attribute :customId, &:custom_id
  attribute :updatedAt, &:updated_at
  attribute :reminderPermission, &:reminder_permission
  attribute :phoneNumbersDetails, &:phone_numbers_details
  attribute :emailsDetails, &:emails_details
  attribute :addressDetails, &:address_details
  attribute :label, &:name
  attribute :value, &:id
  attribute :rank, &:rank
  attribute :displayAddress, &:display_address
  attribute :simpleAddress, &:simple_address

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
end
