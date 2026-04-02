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
    
    # Sessionから取得した場合はStringキー、通常はSymbolキー
    client_id = credentials[:client_id] || credentials["client_id"]
    client_secret = credentials[:client_secret] || credentials["client_secret"]
    
    Rails.logger.info("[OmniauthSetup] Setup called with credentials: client_id=#{client_id.present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] Credentials: #{credentials.inspect}")
    Rails.logger.info("[OmniauthSetup] Extracted client_id: #{client_id}")
    
    # Store credentials in session for callback phase
    if client_id.present?
      @request.session[:line_oauth_credentials] = credentials
    end
    
    @env['omniauth.strategy'].options[:client_id] = client_id if client_id
    @env['omniauth.strategy'].options[:client_secret] = client_secret if client_secret
    @env['omniauth.strategy'].options[:scope] = "profile openid email"
    
    Rails.logger.info("[OmniauthSetup] Final strategy options: client_id=#{@env['omniauth.strategy'].options[:client_id]}")
  rescue => e
    Rails.logger.error("[OmniauthSetup] Error in setup: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
  
  # Use the subdomain in the request to find the account with credentials
  def custom_credentials
    # パラメータを最優先（URLクエリパラメータ or POSTボディ）
    # 次にCookie、最後にSession
    oauth_social_account_id = @request.parameters["oauth_social_account_id"].presence || 
                              @request.cookies["oauth_social_account_id"] || 
                              @request.session[:oauth_social_account_id]
    
    who = @request.parameters["whois"].presence || 
          @request.cookies["whois"] || 
          @request.session[:line_oauth_who]
    
    Rails.logger.info("[OmniauthSetup] ===== 認証情報取得開始 =====")
    Rails.logger.info("[OmniauthSetup] Request method: #{@request.request_method}")
    Rails.logger.info("[OmniauthSetup] Request path: #{@request.path}")
    Rails.logger.info("[OmniauthSetup] Parameters keys: #{@request.parameters.keys.join(', ')}")
    Rails.logger.info("[OmniauthSetup] --- パラメータ確認 ---")
    Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (param): #{@request.parameters["oauth_social_account_id"].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup]   whois (param): #{@request.parameters["whois"].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] --- Cookie確認 ---")
    Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (cookie): #{@request.cookies["oauth_social_account_id"].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup]   whois (cookie): #{@request.cookies["whois"].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] --- Session確認 ---")
    Rails.logger.info("[OmniauthSetup]   oauth_social_account_id (session): #{@request.session[:oauth_social_account_id].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup]   line_oauth_who (session): #{@request.session[:line_oauth_who].present? ? 'present' : 'nil'}")
    Rails.logger.info("[OmniauthSetup] --- 採用値 ---")
    Rails.logger.info("[OmniauthSetup]   oauth_social_account_id: #{oauth_social_account_id.present? ? "present (#{oauth_social_account_id[0..20]}...)" : 'nil'}")
    Rails.logger.info("[OmniauthSetup]   who: #{who.present? ? "present (#{who[0..20]}...)" : 'nil'}")
    
    # Callbackフェーズの判定: パラメータに oauth_social_account_id も whois も無い場合
    # (LINEからのリダイレクト後なので、URLパラメータには code と state のみ)
    is_callback_phase = @request.parameters["oauth_social_account_id"].blank? && 
                        @request.parameters["whois"].blank? &&
                        (@request.parameters["code"].present? || @request.path.include?("callback"))
    
    Rails.logger.info("[OmniauthSetup] フェーズ判定: #{is_callback_phase ? 'Callback' : '開始'}")
    
    # Callbackフェーズでは、Sessionから認証情報を取得
    if is_callback_phase && @request.session[:line_oauth_credentials].present?
      Rails.logger.info("[OmniauthSetup] ✅ Using credentials from session (callback phase)")
      return @request.session[:line_oauth_credentials]
    end
    
    # 開始フェーズ: whoやoauth_social_account_idをSessionに保存（callbackフェーズ用）
    # 予約画面モードでもSessionに保存（Cookieは使わないが、Sessionは使う）
    Rails.logger.info("[OmniauthSetup] 💾 開始フェーズ: SessionにIDを保存")
    
    # パラメータで明示的に指定された場合、反対側の認証情報を完全にクリアして混在を防ぐ
    # whois（Toruya共通ログイン）がパラメータにあれば、店舗固有の値をセッション・Cookie・変数すべてからクリア
    if @request.parameters["whois"].present?
      @request.session.delete(:oauth_social_account_id)
      @request.session.delete(:line_oauth_credentials)
      # oauth_social_account_idを完全にnilにする（Cookieに残存していても無視）
      oauth_social_account_id = nil
      Rails.logger.info("[OmniauthSetup]   whoisパラメータ検出 → oauth_social_account_idを完全にクリア（session/cookie/変数すべて）")
    end
    
    # oauth_social_account_id（店舗固有ログイン）がパラメータにあれば、Toruya共通の値をセッション・Cookie・変数すべてからクリア
    if @request.parameters["oauth_social_account_id"].present?
      @request.session.delete(:line_oauth_who)
      @request.session.delete(:line_oauth_who_routing)
      @request.session.delete(:line_oauth_credentials)
      # whoを完全にnilにする（Cookieに残存していても無視）
      who = nil
      Rails.logger.info("[OmniauthSetup]   oauth_social_account_idパラメータ検出 → whoisを完全にクリア（session/cookie/変数すべて）")
    end
    
    if who.present?
      @request.session[:line_oauth_who] = who
      Rails.logger.info("[OmniauthSetup]   保存: line_oauth_who")
    end

    # who_routing: コールバック時のルーティング判定用
    # oauth_social_account_idがパラメータにある場合（店舗固有ログイン）は、
    # cookieに残存しているwhoを拾わない（別フローのwhoが混入するのを防ぐ）
    who_routing = @request.parameters["who"].presence
    if who_routing.blank? && @request.parameters["oauth_social_account_id"].blank?
      who_routing = @request.cookies["who"]
    end
    if who_routing.present?
      @request.session[:line_oauth_who_routing] = who_routing
      Rails.logger.info("[OmniauthSetup]   保存: line_oauth_who_routing (コールバックルーティング用)")
    end
    
    if oauth_social_account_id.present?
      @request.session[:oauth_social_account_id] = oauth_social_account_id
      Rails.logger.info("[OmniauthSetup]   保存: oauth_social_account_id")
    end
    
    # oauth_redirect_to_urlもSessionに保存（Callbackフェーズで復元するため）
    oauth_redirect_to_url = @request.parameters["oauth_redirect_to_url"].presence
    if oauth_redirect_to_url.present?
      @request.session[:oauth_redirect_to_url] = oauth_redirect_to_url
      Rails.logger.info("[OmniauthSetup]   保存: oauth_redirect_to_url")
    end
    
    # 予約情報もSessionに保存（Callbackフェーズで復元するため）
    %w[booking_option_ids booking_date booking_at staff_id customer_id].each do |key|
      if @request.parameters[key].present?
        @request.session["oauth_#{key}"] = @request.parameters[key]
        Rails.logger.info("[OmniauthSetup]   保存: #{key} = #{@request.parameters[key]}")
      end
    end

    # 優先度1: oauth_social_account_id（店舗固有のLINE Login）
    if oauth_social_account_id.present?
      begin
        account_id = MessageEncryptor.decrypt(oauth_social_account_id)
        account = SocialAccount.find(account_id)
        
        Rails.logger.info("[OmniauthSetup] ✅ 店舗固有のLINE Login認証情報を使用")
        Rails.logger.info("[OmniauthSetup]   SocialAccount ID: #{account_id}")
        Rails.logger.info("[OmniauthSetup]   店舗: #{account.user&.shop&.display_name || 'N/A'}")
        Rails.logger.info("[OmniauthSetup]   login_channel_id: #{account.login_channel_id.present? ? 'present' : 'nil'}")
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
