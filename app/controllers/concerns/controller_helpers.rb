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
    render json: json_response(outcome, data), status: outcome.valid? ? :ok : :bad_request
  end
end
