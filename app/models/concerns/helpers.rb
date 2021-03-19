# frozen_string_literal: true

module Helpers
  extend ActiveSupport::Concern

  def display_name
    short_name.presence || name
  end
end
