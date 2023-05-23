# frozen_string_literal: true

class WebhooksController < ActionController::Base
  skip_before_action :verify_authenticity_token
  skip_before_action :track_ahoy_visit
  abstract!
end
