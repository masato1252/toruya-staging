# frozen_string_literal: true

module UserBotCookies
  PREPEND = "user_bot".freeze

  def user_bot_cookies(key)
    cookies.encrypted[prepend_key(key)]
  end
  
  def cookie_domain
    if Rails.env.production?
      # Use the host from environment variable or request
      host = ENV['HEROKU_APP_DEFAULT_DOMAIN_NAME'] || ENV['APP_HOST'] || request.host
      
      # Extract base domain (e.g., toruya-staging.com from www.toruya-staging.com)
      # If host is like xxx.herokuapp.com, use :all
      # If host is custom domain, extract base domain
      if host.include?('herokuapp.com')
        :all
      else
        # Extract base domain by removing subdomain if present
        parts = host.split('.')
        if parts.length > 2
          ".#{parts[-2..-1].join('.')}"
        else
          ".#{host}"
        end
      end
    else
      :all
    end
  end

  def write_user_bot_cookies(key, value)
    cookie_key = prepend_key(key)
    domain = cookie_domain
    
    cookies.delete(cookie_key, domain: domain)
    
    # Use encrypted cookies with explicit domain setting
    cookie_options = {
      value: value,
      expires: 20.years.from_now,
      domain: domain,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
    
    Rails.logger.info("[UserBotCookies] Setting cookie #{cookie_key} with value: #{value.inspect}, domain: #{domain}, secure: #{cookie_options[:secure]}, host: #{request.host}")
    
    cookies.encrypted[cookie_key] = cookie_options
    
    # Verify the cookie was set
    Rails.logger.info("[UserBotCookies] Cookie #{cookie_key} set. Can read back: #{cookies.encrypted[cookie_key].present?}")
  end

  def delete_user_bot_cookies(key)
    cookie_key = prepend_key(key)
    domain = cookie_domain
    cookies.delete(cookie_key, domain: domain)
    cookies.encrypted.delete(cookie_key)
    Rails.logger.info("[UserBotCookies] Deleted cookie #{cookie_key} with domain: #{domain}")
  end

  def prepend_key(key)
    "#{PREPEND}_#{key}"
  end
end
