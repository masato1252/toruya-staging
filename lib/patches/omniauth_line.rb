# https://github.com/kazasiki/omniauth-line/pull/26
module LineOAuth2
  def callback_url
    # Fixes regression in omniauth-oauth2 v1.4.0 by https://github.com/intridea/omniauth-oauth2/commit/85fdbe117c2a4400d001a6368cc359d88f40abc7
    options[:callback_url] || (full_host + script_name + callback_path)
  end
end

OmniAuth::Strategies::Line.include(LineOAuth2)
