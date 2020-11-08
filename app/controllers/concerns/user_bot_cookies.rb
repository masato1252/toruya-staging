module UserBotCookies
  PREPEND = "user_bot".freeze

  def user_bot_cookies(key)
    cookies[prepend_key(key)]
  end

  def write_user_bot_cookies(key, value)
    cookies.permanent[prepend_key(key)] = value
  end

  def prepend_key(key)
    "#{PREPEND}_#{key}"
  end
end
