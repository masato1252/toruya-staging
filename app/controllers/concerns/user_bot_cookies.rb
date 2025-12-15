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
      
      # For Heroku domains, don't set domain (let browser handle it)
      # This is more reliable than using :all
      if host.include?('herokuapp.com')
        :all  # Signal to not set domain attribute
      elsif ENV['HEROKU_APP_DEFAULT_DOMAIN_NAME'] && !ENV['HEROKU_APP_DEFAULT_DOMAIN_NAME'].include?('herokuapp.com')
        # For custom domains, extract base domain
        parts = host.split('.')
        if parts.length > 2
          ".#{parts[-2..-1].join('.')}"
        else
          ".#{host}"
        end
      else
        :all
      end
    else
      :all
    end
  end

  def write_user_bot_cookies(key, value)
    cookie_key = prepend_key(key)
    domain = cookie_domain
    
    # Delete old cookie first
    cookies.delete(cookie_key, domain: domain) if domain != :all
    cookies.delete(cookie_key) if domain == :all
    
    # Use encrypted cookies with explicit domain setting
    cookie_options = {
      value: value,
      expires: 20.years.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :none  # Required for cross-site redirects from LINE
    }
    
    # Only set domain if not using herokuapp.com
    if domain != :all
      cookie_options[:domain] = domain
    end
    
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
