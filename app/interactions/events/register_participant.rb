# frozen_string_literal: true

module Events
  class RegisterParticipant < ActiveInteraction::Base
    object :event
    object :event_line_user

    array :business_types, default: []
    string :business_age, default: nil
    array :concern_labels, default: []
    string :concern_other, default: nil
    string :first_name, default: nil
    string :last_name, default: nil
    string :phone_number, default: nil

    def execute
      update_event_line_user_profile

      participant = event.event_participants.find_or_initialize_by(event_line_user_id: event_line_user.id)

      return participant unless participant.new_record?

      labels = sanitized_concern_labels
      participant.assign_attributes(
        business_types: business_types.reject(&:blank?),
        business_age: business_age.presence,
        concern_labels: labels,
        concern_categories: derive_concern_categories(labels),
        concern_other: concern_other.presence,
        registered_at: Time.current
      )

      unless participant.save
        errors.merge!(participant.errors)
        return
      end

      participant
    end

    private

    def update_event_line_user_profile
      attrs = {}
      attrs[:first_name] = first_name if first_name.present? && event_line_user.first_name.blank?
      attrs[:last_name] = last_name if last_name.present? && event_line_user.last_name.blank?
      attrs[:phone_number] = phone_number if phone_number.present? && event_line_user.phone_number.blank?
      attrs[:business_types] = business_types.reject(&:blank?) if business_types.present?
      attrs[:business_age] = business_age.presence if business_age.present?

      event_line_user.update(attrs) if attrs.present?
    end

    def sanitized_concern_labels
      (concern_labels || []).reject(&:blank?).first(6)
    end

    def derive_concern_categories(labels)
      labels.filter_map { |label| EventParticipant::CONCERN_MAPPING[label]&.dig(:category) }.uniq
    end
  end
end
