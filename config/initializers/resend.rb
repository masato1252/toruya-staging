# frozen_string_literal: true

require Rails.root.join("lib/kasaike/resend_delivery_method")

if ENV["RESEND_API_KEY"].present?
  Resend.api_key = ENV["RESEND_API_KEY"]
end

Rails.application.config.to_prepare do
  ActionMailer::Base.add_delivery_method :kasaike_resend, Kasaike::ResendDeliveryMethod
end
