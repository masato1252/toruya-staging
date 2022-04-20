# frozen_string_literal: true

module ControllerHelpers
  extend ActiveSupport::Concern

  private

  def json_response(outcome, data = {})
    {
      status: outcome.valid? ? "successful" : "failed",
      error_message: outcome.errors.full_messages.join(", ")
    }.merge!(data)
  end

  def return_json_response(outcome, data = {})
    if outcome.invalid?
      Rollbar.error("#{outcome.class} service failed", {
        errors: outcome.errors.details
      })
    end
    render json: json_response(outcome, data), status: outcome.valid? ? :ok : :bad_request
  end
end
