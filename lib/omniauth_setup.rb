# frozen_string_literal: true

require "message_encryptor"

class OmniauthSetup
  # OmniAuth expects the class passed to setup to respond to the #call method.
  # env - Rack environment
  def self.call(env)
    new(env).setup
  end

  # Assign variables and create a request object for use later.
  # env - Rack environment
  def initialize(env)
    @env = env
    @request = ActionDispatch::Request.new(env)
  end

  # The main purpose of this method is to set the consumer key and secret.
  def setup
    Rails.logger.info("[OmniauthSetup] Setup method called!")
    
    credentials = custom_credentials
    
    Rails.logger.info("[OmniauthSetup] Setup called with credentials: client_id=#{credentials[:client_id].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] Credentials: #{credentials.inspect}")
    
    # Store credentials in session for callback phase
    if credentials[:client_id].present?
      @request.session[:line_oauth_credentials] = credentials
    end
    
    @env['omniauth.strategy'].options[:client_id] = credentials[:client_id] if credentials[:client_id]
    @env['omniauth.strategy'].options[:client_secret] = credentials[:client_secret] if credentials[:client_secret]
    @env['omniauth.strategy'].options[:scope] = "profile openid email"
    
    Rails.logger.info("[OmniauthSetup] Final strategy options: client_id=#{@env['omniauth.strategy'].options[:client_id]}")
  rescue => e
    Rails.logger.error("[OmniauthSetup] Error in setup: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end

  # Use the subdomain in the request to find the account with credentials
  def custom_credentials
    Rails.logger.info("[OmniauthSetup] ===== 認証情報取得開始 =====")
    Rails.logger.info("[OmniauthSetup] Request method: #{@request.request_method}")
    Rails.logger.info("[OmniauthSetup] Request path: #{@request.path}")
    Rails.logger.info("[OmniauthSetup] Parameters keys: #{@request.parameters.keys.join(', ')}")
    
    # 予約画面経由かどうかを判定（oauth_redirect_to_url に "booking" が含まれているか）
    oauth_redirect_to_url = @request.parameters["oauth_redirect_to_url"].to_s
    is_booking_flow = oauth_redirect_to_url.include?("booking")
    
    Rails.logger.info("[OmniauthSetup] 予約画面経由: #{is_booking_flow ? 'YES' : 'NO'}")
    Rails.logger.info("[OmniauthSetup] oauth_redirect_to_url: #{oauth_redirect_to_url[0..50]}...")
    
    # 認証情報の取得（パラメータ → Cookie → Session の優先順位）
    # 予約画面経由の場合はCookieを無視
    if is_booking_flow
      # 予約画面モード: パラメータのみを使用（Cookie無視、Sessionは使用）
      oauth_social_account_id = @request.parameters["oauth_social_account_id"].presence || 
                                @request.session[:oauth_social_account_id]
      who = @request.parameters["whois"].presence || 
            @request.session[:line_oauth_who]
      
      Rails.logger.info("[OmniauthSetup] 🔒 予約画面モード: パラメータ → Session（Cookie無視）")
      Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (param): #{@request.parameters["oauth_social_account_id"].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (session): #{@request.session[:oauth_social_account_id].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   whois (param): #{@request.parameters["whois"].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   whois (session): #{@request.session[:line_oauth_who].present? ? 'present' : 'nil'}")
    else
      # 通常モード: パラメータ → Cookie → Session
      oauth_social_account_id = @request.parameters["oauth_social_account_id"].presence || 
                                @request.cookies["oauth_social_account_id"] || 
                                @request.session[:oauth_social_account_id]
      
      who = @request.parameters["whois"].presence || 
            @request.cookies["whois"] || 
            @request.session[:line_oauth_who]
      
      Rails.logger.info("[OmniauthSetup] 📋 通常モード: パラメータ → Cookie → Session")
      Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (param): #{@request.parameters["oauth_social_account_id"].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (cookie): #{@request.cookies["oauth_social_account_id"].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (session): #{@request.session[:oauth_social_account_id].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   whois (param): #{@request.parameters["whois"].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   whois (cookie): #{@request.cookies["whois"].present? ? 'present' : 'nil'}")
      Rails.logger.info("[OmniauthSetup]   whois (session): #{@request.session[:line_oauth_who].present? ? 'present' : 'nil'}")
    end
    
    Rails.logger.info("[OmniauthSetup] --- 採用値 ---")
    Rails.logger.info("[OmniauthSetup]   oauth_social_account_id: #{oauth_social_account_id.present? ? "present (#{oauth_social_account_id[0..20]}...)" : 'nil'}")
    Rails.logger.info("[OmniauthSetup]   who: #{who.present? ? "present (#{who[0..20]}...)" : 'nil'}")
    
    # Callbackフェーズでは、Sessionから認証情報を取得
    if @request.session[:line_oauth_credentials].present?
      Rails.logger.info("[OmniauthSetup] ✅ Using credentials from session (callback phase)")
      return @request.session[:line_oauth_credentials]
    end
    
    # 開始フェーズ: whoやoauth_social_account_idをSessionに保存（callbackフェーズ用）
    # 予約画面モードでもSessionに保存（Cookieは使わないが、Sessionは使う）
    Rails.logger.info("[OmniauthSetup] 💾 開始フェーズ: SessionにIDを保存")
    
    if who.present?
      @request.session[:line_oauth_who] = who
      Rails.logger.info("[OmniauthSetup]   保存: line_oauth_who")
    end
    
    if oauth_social_account_id.present?
      @request.session[:oauth_social_account_id] = oauth_social_account_id
      Rails.logger.info("[OmniauthSetup]   保存: oauth_social_account_id")
    end
    
    # 優先度1: oauth_social_account_id（店舗固有のLINE Login）
    if oauth_social_account_id.present?
      begin
        account_id = MessageEncryptor.decrypt(oauth_social_account_id)
        account = SocialAccount.find(account_id)
        
        Rails.logger.info("[OmniauthSetup] ✅ 店舗固有のLINE Login認証情報を使用")
        Rails.logger.info("[OmniauthSetup]   SocialAccount ID: #{account_id}")
        Rails.logger.info("[OmniauthSetup]   店舗: #{account.user&.shop&.display_name || 'N/A'}")
        Rails.logger.info("[OmniauthSetup]   login_channel_id: #{account.login_channel_id.present? ? "present (#{account.login_channel_id})" : 'nil'}")
        Rails.logger.info("[OmniauthSetup]   raw_login_channel_secret: #{account.raw_login_channel_secret.present? ? 'present' : 'nil'}")
        
        return {
          client_id: account.login_channel_id,
          client_secret: account.raw_login_channel_secret
        }
      rescue ActiveSupport::MessageVerifier::InvalidSignature => e
        Rails.logger.error("[OmniauthSetup] ❌ oauth_social_account_id の復号化に失敗: #{e.message}")
        Rails.logger.error("[OmniauthSetup]    暗号化された値: #{oauth_social_account_id[0..50]}...")
        return {}
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("[OmniauthSetup] ❌ SocialAccountが見つかりません: #{e.message}")
        return {}
      rescue => e
        Rails.logger.error("[OmniauthSetup] ❌ SocialAccount読み込みエラー: #{e.class} - #{e.message}")
        return {}
      end
    end
    
    # 優先度2: whois（Toruya共通のLINE Login）
    if who.present?
      begin
        decrypted_who = MessageEncryptor.decrypt(who)
        
        if decrypted_who == CallbacksController::TORUYA_USER
          Rails.logger.info("[OmniauthSetup] ✅ Toruya共通 (JA) LINE Login認証情報を使用")
          return {
            client_id: Rails.application.secrets[:ja][:toruya_line_login_id],
            client_secret: Rails.application.secrets[:ja][:toruya_line_login_secret]
          }
        elsif decrypted_who == CallbacksController::TW_TORUYA_USER
          Rails.logger.info("[OmniauthSetup] ✅ Toruya共通 (TW) LINE Login認証情報を使用")
          return {
            client_id: Rails.application.secrets[:tw][:toruya_line_login_id],
            client_secret: Rails.application.secrets[:tw][:toruya_line_login_secret]
          }
        else
          Rails.logger.warn("[OmniauthSetup] ⚠️ 不明なwhois値: #{decrypted_who}")
        end
      rescue => e
        Rails.logger.error("[OmniauthSetup] ❌ whoisの復号化に失敗: #{e.message}")
      end
    end
    
    # どの認証情報も取得できなかった場合
    Rails.logger.error("[OmniauthSetup] ❌ 認証情報が見つかりませんでした")
    Rails.logger.error("[OmniauthSetup]    oauth_social_account_id: #{oauth_social_account_id.inspect}")
    Rails.logger.error("[OmniauthSetup]    who: #{who.inspect}")
    Rollbar.error("Unexpected line callback", request: @request, who: who, cookies: @request.cookies.to_h.keys, session_keys: @request.session.to_h.keys) if Rails.configuration.x.env.production?
    {}
  end
end
