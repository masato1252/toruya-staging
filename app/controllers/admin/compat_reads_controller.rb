# frozen_string_literal: true

module Admin
  # Same-origin gateway for browser admin reads. AdminController authenticates
  # the Devise session before CompatSession signs and forwards this request.
  class CompatReadsController < AdminController
    def show
      path = params[:path].to_s
      unless path.start_with?("/admin/") && !path.include?("://") && !path.include?("\\")
        render json: { status: "failed", error_message: "Invalid admin compat path" }, status: :bad_request
        return
      end

      uri = URI(path)
      body = compat_fetch_v1_json(uri.path, Rack::Utils.parse_nested_query(uri.query))
      unless body
        render json: { status: "failed", error_message: "Admin compatibility API unavailable" }, status: :bad_gateway
        return
      end

      render json: body
    end
  end
end
