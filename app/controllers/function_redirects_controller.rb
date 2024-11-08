class FunctionRedirectsController < ActionController::Base
  def redirect
    url = params[:content]
    source_type = params[:source_type]
    source_id = params[:source_id]
    action_type = params[:action_type]

    # Track the access
    if url && source_id && source_type && action_type
      function_access = FunctionAccess.track_access(
        content: url,
        source_type: source_type,
        source_id: source_id,
        action_type: action_type
      )

      redirect_to append_function_access_id(url, function_access&.id)
    else
      Rollbar.error("FunctionRedirectsController#redirect",
        url: url,
        source_type: source_type,
        source_id: source_id,
        action_type: action_type
      )
      redirect_to url
    end
  end

  private

  def append_function_access_id(url, function_access_id)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || "").to_h
    params["function_access_id"] = function_access_id.to_s
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end 
