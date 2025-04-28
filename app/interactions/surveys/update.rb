# frozen_string_literal: true

module Surveys
  class Update < ActiveInteraction::Base
    object :survey
    string :update_attribute

    hash :attrs, default: nil, strip: false do
      boolean :active
    end

    def execute
      survey.transaction do
        case update_attribute
        when "active"
          survey.update(attrs.slice(update_attribute))
        end
      end
    end
  end
end
