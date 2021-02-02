# frozen_string_literal: true

module CustomSchedules
  class Delete < ActiveInteraction::Base
    object :custom_schedule

    def execute
      custom_schedule.destroy
    end
  end
end
