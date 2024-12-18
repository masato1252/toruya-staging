# frozen_string_literal: true

module UserSettings
  class Update < ActiveInteraction::Base
    object :user_setting
    string :update_attribute

    hash :attrs, default: nil, strip: false do
      boolean :line_contact_customer_name_required, default: false
      boolean :booking_options_menu_concept, default: false
    end

    def execute
      user_setting.transaction do
        case update_attribute
        when "line_contact_customer_name_required", "booking_options_menu_concept"
          user_setting.update(attrs.slice(update_attribute))
        end

        if user_setting.errors.present?
          errors.merge!(user_setting.errors)
        end

        user_setting
      end
    end
  end
end
