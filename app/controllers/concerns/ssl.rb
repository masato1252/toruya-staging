module Ssl
  extend ActiveSupport::Concern

  included do
    force_ssl if: :ssl_configured?
  end

  def ssl_configured?
    ENV["HTTP_PROTOCOL"] == "https"
  end
end
