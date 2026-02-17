# frozen_string_literal: true

# OmniAuth configuration for proper callback URL handling
# MAIL_DOMAINを使用して、本番環境で正しいドメイン（manager.toruya.com）を使用する
OmniAuth.config.full_host = lambda do |env|
  scheme = ENV['HTTP_PROTOCOL'] || 'https'
  host = ENV['MAIL_DOMAIN'] || env['HTTP_HOST']
  "#{scheme}://#{host}"
end

# 注: DynamicLineOAuthMiddleware は削除しました。
# env['omniauth.strategy'] はミドルウェア実行時にnilのため実質No-opであり、
# 認証情報の設定はすべて OmniauthSetup (lib/omniauth_setup.rb) で行っています。
