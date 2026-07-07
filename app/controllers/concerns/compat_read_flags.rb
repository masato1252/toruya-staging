# frozen_string_literal: true

# Shared compat read gate — requires both flag and v1 API origin.
module CompatReadFlags
  extend ActiveSupport::Concern

  included do
    helper_method :compat_read_enabled?, :compat_read_data_plane? if respond_to?(:helper_method)
  end

  def compat_read_data_plane?
    ENV["COMPAT_API_READ_ENABLED"] == "true" && ENV["COMPAT_API_ORIGIN"].present?
  end

  def compat_read_enabled?
    compat_read_data_plane?
  end
end
