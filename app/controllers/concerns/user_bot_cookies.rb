# frozen_string_literal: true

module UserBotCookies
  PREPEND = "user_bot".freeze

  def user_bot_cookies(key)
    cookies.encrypted[prepend_key(key)]
  end

  def write_user_bot_cookies(key, value)
    cookies.encrypted.permanent[prepend_key(key)] = value
  end

  def delete_user_bot_cookies(key)
    cookies.delete(prepend_key(key))
  end

  def prepend_key(key)
    "#{PREPEND}_#{key}"
  end
end
