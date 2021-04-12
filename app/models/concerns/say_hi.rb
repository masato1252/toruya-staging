# frozen_string_literal: true

module SayHi
  extend ActiveSupport::Concern

  included do
    after_commit :say_hi, on: :create
  end

  def say_hi
    if Rails.configuration.x.env.production?
      HiJob.perform_later(self)
    end
  end
end
