# frozen_string_literal: true

# OmniAuth configuration for proper callback URL handling
# 本番/ステージング: MAIL_DOMAINで正しいドメインを使用
# development: リクエストのホストをそのまま使用（localhost検証対応）
OmniAuth.config.full_host = lambda do |env|
  request = Rack::Request.new(env)
  if request.host == 'localhost' || request.host == '127.0.0.1'
    scheme = request.scheme || 'https'
    "#{scheme}://#{request.host_with_port}"
  else
    scheme = ENV['HTTP_PROTOCOL'] || 'https'
    host = ENV['MAIL_DOMAIN'] || env['HTTP_HOST']
    "#{scheme}://#{host}"
  end
end
