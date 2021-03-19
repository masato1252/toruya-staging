# frozen_string_literal: true

class ActiveInteraction::Base
  class << self
    def class_name
      self.name.split("::").last.underscore
    end
  end
end
