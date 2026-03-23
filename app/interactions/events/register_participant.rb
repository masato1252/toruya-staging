# frozen_string_literal: true

module Events
  class RegisterParticipant < ActiveInteraction::Base
    object :event
    object :social_customer

    array :business_types, default: []
    string :business_age, default: nil
    string :concern_label, default: nil
    string :concern_other, default: nil

    TORUYA_OFFICIAL_USER_ID = 2584

    def execute
      participant = event.event_participants.find_or_initialize_by(social_customer_id: social_customer.id)

      return participant unless participant.new_record?

      concern_category = concern_label.present? ? EventParticipant.concern_category_for(concern_label) : nil

      participant.assign_attributes(
        user_id: social_customer.customer&.id,
        business_types: business_types.reject(&:blank?),
        business_age: business_age.presence,
        concern_label: concern_label.presence,
        concern_category: concern_category,
        concern_other: concern_other.presence,
        registered_at: Time.current
      )

      unless participant.save
        errors.merge!(participant.errors)
        return
      end

      save_concern_to_toruya_official(participant, social_customer, concern_label, concern_category)

      participant
    end

    private

    def save_concern_to_toruya_official(participant, social_customer, concern_label, concern_category)
      return unless concern_label.present? && concern_category.present?

      official_user = User.find_by(id: TORUYA_OFFICIAL_USER_ID)
      return unless official_user

      toruya_social_customer = official_user.social_customers.find_by(social_user_id: social_customer.social_user_id)
      return unless toruya_social_customer

      customer = toruya_social_customer.customer
      return unless customer

      concern_note = "concern_category:#{concern_category},concern_label:#{concern_label}"
      existing_memo = customer.memo.to_s

      if existing_memo.include?("concern_category:")
        updated_memo = existing_memo.gsub(/concern_category:[^,\n]+,concern_label:[^\n]+/, concern_note)
      else
        updated_memo = [existing_memo.strip, concern_note].reject(&:blank?).join("\n")
      end

      customer.update_column(:memo, updated_memo)
    rescue => e
      Rollbar.error(e, "Failed to save concern to Toruya official customer", social_customer_id: social_customer.id)
    end
  end
end
