# frozen_string_literal: true

module Surveys
  class Delete < ActiveInteraction::Base
    object :survey

    def execute
      if survey.responses.any?
        survey.update(deleted_at: Time.current)
      else
        survey.destroy
      end
    end
  end
end
